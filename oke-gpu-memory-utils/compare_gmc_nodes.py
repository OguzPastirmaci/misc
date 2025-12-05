#!/usr/bin/env python3

"""
Script to compare OCI GPU Memory Cluster instances with Kubernetes nodes
Uses OCI Python SDK (with instance principal authentication) and Kubernetes Python SDK

Usage: ./compare_gmc_nodes.py <GMC_ID> <GPU_CLIQUE>

Requirements:
    pip install oci kubernetes
    
Note: This script uses OCI instance principal authentication, so it must be run from
      an OCI compute instance with appropriate IAM policies configured.
"""

import argparse
import sys
from typing import Dict, List, Set, Tuple

import oci.auth.signers
import oci.core
from kubernetes import client, config


def get_oci_instances(gmc_id: str) -> Tuple[Dict[str, Dict], List[str], str]:
    """
    Fetch OCI instances from GPU Memory Cluster using OCI SDK.
    Returns a dict mapping instance_id -> instance_info, a sorted list of instance IDs, and compartment_id.
    """
    print("Fetching OCI instances from GPU Memory Cluster...")
    
    try:
        # Initialize OCI client with instance principal authentication
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        compute_client = oci.core.ComputeClient(config={}, signer=signer)
        
        # List all instances in the GPU Memory Cluster
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
        
        # Get compartment_id from the first instance
        compartment_id = instances[0].compartment_id if instances else None
        
        # Create a mapping of instance_id -> instance info
        instance_map = {}
        for instance in instances:
            instance_id = instance.id
            instance_map[instance_id] = {
                "display_name": instance.display_name or "Unknown",
                "lifecycle_state": instance.lifecycle_state or "Unknown",
                "fault_domain": instance.fault_domain or "Unknown",
            }
        
        # Get sorted list of instance IDs
        instance_ids = sorted(instance_map.keys())
        
        return instance_map, instance_ids, compartment_id
        
    except Exception as e:
        print(f"Error: Failed to fetch OCI instances: {e}")
        sys.exit(1)


def get_instance_private_ips(instance_ids: List[str], compartment_id: str) -> Dict[str, str]:
    """
    Fetch private IP addresses for the given instance IDs using OCI SDK.
    Returns a dict mapping instance_id -> private_ip.
    """
    ip_map = {}
    
    try:
        # Initialize OCI clients with instance principal authentication
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        compute_client = oci.core.ComputeClient(config={}, signer=signer)
        network_client = oci.core.VirtualNetworkClient(config={}, signer=signer)
        
        for instance_id in instance_ids:
            try:
                # List VNICs attached to the instance
                vnic_attachments = compute_client.list_vnic_attachments(
                    compartment_id=compartment_id,
                    instance_id=instance_id
                ).data
                
                if vnic_attachments:
                    # Get the primary VNIC's private IP
                    vnic_id = vnic_attachments[0].vnic_id
                    vnic = network_client.get_vnic(vnic_id).data
                    ip_map[instance_id] = vnic.private_ip or "Unknown"
                else:
                    ip_map[instance_id] = "Unknown"
                    
            except Exception:
                ip_map[instance_id] = "Unknown"
    
    except Exception as e:
        print(f"Error: Failed to initialize OCI client: {e}")
        for instance_id in instance_ids:
            ip_map[instance_id] = "Unknown"
    
    return ip_map


def get_k8s_nodes(gpu_clique: str) -> Tuple[Dict[str, str], List[str]]:
    """
    Fetch Kubernetes nodes with the specified clique label using Kubernetes SDK.
    Returns a dict mapping node_ip -> provider_id and a sorted list of provider IDs.
    """
    print(f"Fetching Kubernetes nodes with label nvidia.com/gpu.clique={gpu_clique}...")
    
    try:
        # Load Kubernetes config
        config.load_kube_config()
        v1 = client.CoreV1Api()
        
        # Get nodes with the specified label
        label_selector = f"nvidia.com/gpu.clique={gpu_clique}"
        nodes = v1.list_node(label_selector=label_selector)
        
        if not nodes.items:
            return {}, []
        
        # Get ProviderIDs for each node
        node_to_provider = {}
        for node in nodes.items:
            node_name = node.metadata.name
            provider_id = node.spec.provider_id
            
            if provider_id:
                node_to_provider[node_name] = provider_id
        
        provider_ids = sorted(node_to_provider.values())
        
        return node_to_provider, provider_ids
        
    except Exception as e:
        print(f"Error: Failed to fetch Kubernetes nodes: {e}")
        sys.exit(1)


def compare_instances(oci_ids: Set[str], k8s_ids: Set[str]) -> Tuple[Set[str], Set[str]]:
    """Compare OCI and K8s instance IDs."""
    matching = oci_ids & k8s_ids
    oci_only = oci_ids - k8s_ids
    return matching, oci_only


def print_separator(title: str = ""):
    """Print a formatted separator line."""
    print("=" * 80)
    if title:
        print(title)
        print("=" * 80)


def main():
    parser = argparse.ArgumentParser(
        description="Compare OCI GPU Memory Cluster instances with Kubernetes nodes (SDK version)"
    )
    parser.add_argument("gmc_id", help="OCI GPU Memory Cluster OCID")
    parser.add_argument("gpu_clique", help="GPU Clique label value")
    
    args = parser.parse_args()
    
    # Print header
    print_separator("Comparing OCI GPU Memory Cluster with Kubernetes Nodes")
    print(f"GMC ID:      {args.gmc_id}")
    print(f"GPU Clique:  {args.gpu_clique}")
    print()
    
    # Fetch OCI instances
    oci_instance_map, oci_instance_ids, compartment_id = get_oci_instances(args.gmc_id)
    print(f"Found {len(oci_instance_ids)} OCI instances")
    print()
    
    # Fetch K8s nodes
    node_to_provider, k8s_provider_ids = get_k8s_nodes(args.gpu_clique)
    print(f"Found {len(k8s_provider_ids)} Kubernetes nodes with the label")
    print()
    
    # Compare
    oci_set = set(oci_instance_ids)
    k8s_set = set(k8s_provider_ids)
    matching, oci_only = compare_instances(oci_set, k8s_set)
    
    # Fetch private IPs only for OCI instances without K8s nodes
    oci_ip_map = {}
    if oci_only and compartment_id:
        print(f"Fetching IP addresses for {len(oci_only)} OCI instances without K8s nodes...")
        oci_ip_map = get_instance_private_ips(list(oci_only), compartment_id)
        print()
    
    # Print summary
    print_separator("SUMMARY")
    print(f"Total OCI instances:                    {len(oci_instance_ids)}")
    print(f"Total Kubernetes nodes with label:      {len(k8s_provider_ids)}")
    print(f"Matching instances:                     {len(matching)}")
    print(f"OCI instances without K8s nodes:        {len(oci_only)}")
    print()
    
    # Show matching instances
    if matching:
        print_separator(f"MATCHING INSTANCES ({len(matching)})")
        print(f"{'INSTANCE ID':<90} {'DISPLAY NAME':<30}")
        print("-" * 120)
        for instance_id in sorted(matching):
            display_name = oci_instance_map[instance_id]["display_name"]
            print(f"{instance_id:<90} {display_name:<30}")
        print()
    
    # Show OCI instances without K8s nodes
    if oci_only:
        print_separator(f"OCI INSTANCES WITHOUT KUBERNETES NODES ({len(oci_only)})")
        print(f"{'INSTANCE ID':<90} {'IP ADDRESS':<20} {'DISPLAY NAME':<30} {'STATE':<15} {'FAULT DOMAIN':<20}")
        print("-" * 175)
        for instance_id in sorted(oci_only):
            ip = oci_ip_map.get(instance_id, "Unknown")
            info = oci_instance_map[instance_id]
            print(f"{instance_id:<90} {ip:<20} {info['display_name']:<30} {info['lifecycle_state']:<15} {info['fault_domain']:<20}")
        print()
    
    # Exit with appropriate status
    if oci_only:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
