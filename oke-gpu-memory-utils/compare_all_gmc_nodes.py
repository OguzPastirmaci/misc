#!/usr/bin/env python3

"""
Script to compare ALL OCI GPU Memory Clusters with their corresponding Kubernetes nodes.
Uses OCI Python SDK (with instance principal authentication) and Kubernetes Python SDK.

This script automatically discovers all GMCs and GPU cliques, then runs comparisons.

Usage: ./compare_all_gmc_nodes.py [--compartment-id COMPARTMENT_ID]

Requirements:
    pip install oci kubernetes
    
Note: This script uses OCI instance principal authentication, so it must be run from
      an OCI compute instance with appropriate IAM policies configured.
"""

import argparse
import sys
from typing import Dict, List, Set, Tuple, Optional

import oci.auth.signers
import oci.core
from kubernetes import client, config


def get_instance_metadata_compartment_id() -> Optional[str]:
    """Get compartment ID from instance metadata."""
    try:
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        # Get the compartment ID from the signer's security token
        # The tenancy ID can be used as a fallback, but we need compartment
        return None  # Will need to be provided or discovered another way
    except Exception:
        return None


def list_all_gmcs(compartment_id: str) -> List[Dict]:
    """
    List all GPU Memory Clusters in the compartment.
    Returns a list of GMC info dicts.
    """
    print("Discovering GPU Memory Clusters from OCI...")
    
    try:
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        compute_client = oci.core.ComputeClient(config={}, signer=signer)
        
        gmcs = []
        response = compute_client.list_compute_gpu_memory_clusters(
            compartment_id=compartment_id
        )
        gmcs.extend(response.data.items)
        
        # Handle pagination
        while response.has_next_page:
            response = compute_client.list_compute_gpu_memory_clusters(
                compartment_id=compartment_id,
                page=response.next_page
            )
            gmcs.extend(response.data.items)
        
        # Filter to only ACTIVE GMCs
        active_gmcs = [
            {
                "id": gmc.id,
                "display_name": gmc.display_name or "Unknown",
                "lifecycle_state": gmc.lifecycle_state,
                "instance_count": getattr(gmc, 'size', 'Unknown'),
            }
            for gmc in gmcs
            if gmc.lifecycle_state == "ACTIVE"
        ]
        
        return active_gmcs
        
    except Exception as e:
        print(f"Error: Failed to list GMCs: {e}")
        return []


def get_oci_instances(gmc_id: str) -> Tuple[Dict[str, Dict], List[str], str]:
    """
    Fetch OCI instances from GPU Memory Cluster using OCI SDK.
    Returns a dict mapping instance_id -> instance_info, a sorted list of instance IDs, and compartment_id.
    """
    try:
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        compute_client = oci.core.ComputeClient(config={}, signer=signer)
        
        instances = []
        response = compute_client.list_compute_gpu_memory_cluster_instances(
            compute_gpu_memory_cluster_id=gmc_id
        )
        instances.extend(response.data.items)
        
        # Handle pagination
        while response.has_next_page:
            response = compute_client.list_compute_gpu_memory_cluster_instances(
                compute_gpu_memory_cluster_id=gmc_id,
                page=response.next_page
            )
            instances.extend(response.data.items)
        
        compartment_id = instances[0].compartment_id if instances else None
        
        instance_map = {}
        for instance in instances:
            instance_id = instance.id
            instance_map[instance_id] = {
                "display_name": instance.display_name or "Unknown",
                "lifecycle_state": instance.lifecycle_state or "Unknown",
                "fault_domain": instance.fault_domain or "Unknown",
            }
        
        instance_ids = sorted(instance_map.keys())
        
        return instance_map, instance_ids, compartment_id
        
    except Exception as e:
        print(f"  Error fetching instances: {e}")
        return {}, [], None


def get_instance_private_ips(instance_ids: List[str], compartment_id: str) -> Dict[str, str]:
    """
    Fetch private IP addresses for the given instance IDs using OCI SDK.
    Returns a dict mapping instance_id -> private_ip.
    """
    ip_map = {}
    
    try:
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        compute_client = oci.core.ComputeClient(config={}, signer=signer)
        network_client = oci.core.VirtualNetworkClient(config={}, signer=signer)
        
        for instance_id in instance_ids:
            try:
                vnic_attachments = compute_client.list_vnic_attachments(
                    compartment_id=compartment_id,
                    instance_id=instance_id
                ).data
                
                if vnic_attachments:
                    vnic_id = vnic_attachments[0].vnic_id
                    vnic = network_client.get_vnic(vnic_id).data
                    ip_map[instance_id] = vnic.private_ip or "Unknown"
                else:
                    ip_map[instance_id] = "Unknown"
                    
            except Exception:
                ip_map[instance_id] = "Unknown"
    
    except Exception as e:
        print(f"  Error fetching IPs: {e}")
        for instance_id in instance_ids:
            ip_map[instance_id] = "Unknown"
    
    return ip_map


def get_all_k8s_cliques() -> Dict[str, Dict[str, str]]:
    """
    Fetch all Kubernetes nodes with gpu.clique labels.
    Returns a dict mapping clique_value -> {node_ip -> provider_id}.
    """
    print("Discovering GPU cliques from Kubernetes nodes...")
    
    try:
        config.load_kube_config()
        v1 = client.CoreV1Api()
        
        # Get all nodes with the gpu.clique label
        nodes = v1.list_node(label_selector="nvidia.com/gpu.clique")
        
        if not nodes.items:
            return {}
        
        cliques = {}
        for node in nodes.items:
            labels = node.metadata.labels or {}
            clique = labels.get("nvidia.com/gpu.clique")
            
            if clique:
                node_name = node.metadata.name
                provider_id = node.spec.provider_id
                
                if clique not in cliques:
                    cliques[clique] = {}
                
                if provider_id:
                    cliques[clique][node_name] = provider_id
        
        return cliques
        
    except Exception as e:
        print(f"Error: Failed to fetch Kubernetes nodes: {e}")
        return {}


def match_gmc_to_clique(gmc_instance_ids: Set[str], cliques: Dict[str, Dict[str, str]]) -> Optional[str]:
    """
    Find which clique matches the GMC instances.
    Returns the clique value or None if no match found.
    """
    for clique, nodes in cliques.items():
        clique_provider_ids = set(nodes.values())
        # Check if any GMC instance is in this clique
        if gmc_instance_ids & clique_provider_ids:
            return clique
    return None


def compare_instances(oci_ids: Set[str], k8s_ids: Set[str]) -> Tuple[Set[str], Set[str]]:
    """Compare OCI and K8s instance IDs."""
    matching = oci_ids & k8s_ids
    oci_only = oci_ids - k8s_ids
    return matching, oci_only


def print_separator(title: str = "", char: str = "="):
    """Print a formatted separator line."""
    print(char * 80)
    if title:
        print(title)
        print(char * 80)


def run_comparison_for_gmc(
    gmc_info: Dict,
    cliques: Dict[str, Dict[str, str]],
    verbose: bool = False
) -> Tuple[int, int, int, Optional[str], List[Dict]]:
    """
    Run comparison for a single GMC.
    Returns (total_oci, total_k8s, matching, clique_id, missing_instances_info).
    """
    gmc_id = gmc_info["id"]
    gmc_name = gmc_info["display_name"]
    
    # Get OCI instances
    oci_instance_map, oci_instance_ids, compartment_id = get_oci_instances(gmc_id)
    
    if not oci_instance_ids:
        return 0, 0, 0, None, []
    
    oci_set = set(oci_instance_ids)
    
    # Find matching clique
    clique = match_gmc_to_clique(oci_set, cliques)
    
    if not clique:
        # No matching clique found - all instances are missing from K8s
        missing_info = []
        if compartment_id:
            ip_map = get_instance_private_ips(oci_instance_ids, compartment_id)
            for instance_id in oci_instance_ids:
                info = oci_instance_map[instance_id]
                missing_info.append({
                    "instance_id": instance_id,
                    "ip": ip_map.get(instance_id, "Unknown"),
                    "display_name": info["display_name"],
                    "lifecycle_state": info["lifecycle_state"],
                    "fault_domain": info["fault_domain"],
                })
        return len(oci_instance_ids), 0, 0, None, missing_info
    
    # Get K8s nodes for this clique
    k8s_provider_ids = set(cliques[clique].values())
    
    matching, oci_only = compare_instances(oci_set, k8s_provider_ids)
    
    # Get info for missing instances
    missing_info = []
    if oci_only and compartment_id:
        ip_map = get_instance_private_ips(list(oci_only), compartment_id)
        for instance_id in sorted(oci_only):
            info = oci_instance_map[instance_id]
            missing_info.append({
                "instance_id": instance_id,
                "ip": ip_map.get(instance_id, "Unknown"),
                "display_name": info["display_name"],
                "lifecycle_state": info["lifecycle_state"],
                "fault_domain": info["fault_domain"],
            })
    
    return len(oci_instance_ids), len(k8s_provider_ids), len(matching), clique, missing_info


def main():
    parser = argparse.ArgumentParser(
        description="Compare ALL OCI GPU Memory Clusters with Kubernetes nodes"
    )
    parser.add_argument(
        "-c", "--compartment-id",
        required=True,
        help="OCI Compartment OCID to search for GMCs"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show detailed output for each GMC"
    )
    
    args = parser.parse_args()
    
    print_separator("Comparing All OCI GPU Memory Clusters with Kubernetes Nodes")
    print()
    
    # Discover all GMCs
    gmcs = list_all_gmcs(args.compartment_id)
    print(f"Found {len(gmcs)} active GPU Memory Clusters")
    print()
    
    if not gmcs:
        print("No active GMCs found.")
        sys.exit(0)
    
    # Discover all K8s cliques
    cliques = get_all_k8s_cliques()
    print(f"Found {len(cliques)} GPU cliques in Kubernetes")
    print()
    
    # Run comparison for each GMC
    print_separator("COMPARISON RESULTS")
    
    total_missing = 0
    all_missing_instances = []
    
    print(f"\n{'GMC NAME':<40} {'CLIQUE ID':<50} {'OCI':<6} {'K8S':<6} {'MISS':<6} {'STATUS'}")
    print("-" * 120)
    
    for gmc in sorted(gmcs, key=lambda x: x["display_name"]):
        oci_count, k8s_count, match_count, clique_id, missing = run_comparison_for_gmc(
            gmc, cliques, args.verbose
        )
        
        missing_count = oci_count - match_count
        total_missing += missing_count
        
        status = "OK" if missing_count == 0 else "MISSING"
        clique_display = clique_id if clique_id else "N/A"
        
        print(f"{gmc['display_name']:<40} {clique_display:<50} {oci_count:<6} {k8s_count:<6} {missing_count:<6} {status}")
        
        if missing:
            for m in missing:
                m["gmc_name"] = gmc["display_name"]
            all_missing_instances.extend(missing)
    
    print()
    
    # Summary
    print_separator("SUMMARY")
    print(f"Total GMCs checked:           {len(gmcs)}")
    print(f"Total GPU cliques in K8s:     {len(cliques)}")
    print(f"Total missing instances:      {total_missing}")
    print()
    
    # Show all missing instances
    if all_missing_instances:
        print_separator(f"ALL MISSING INSTANCES ({len(all_missing_instances)})")
        print(f"{'GMC NAME':<30} {'IP ADDRESS':<18} {'DISPLAY NAME':<30} {'STATE'}")
        print("-" * 100)
        for m in sorted(all_missing_instances, key=lambda x: (x["gmc_name"], x["ip"])):
            print(f"{m['gmc_name']:<30} {m['ip']:<18} {m['display_name']:<30} {m['lifecycle_state']}")
        print()
        sys.exit(1)
    else:
        print("All OCI instances have corresponding Kubernetes nodes.")
        sys.exit(0)


if __name__ == "__main__":
    main()

