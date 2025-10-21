#!/usr/bin/env python3
"""Generate table of GPU cliques using OCI Python SDK with instance principals."""

import argparse
import csv
import os
import sys
import textwrap
from io import StringIO
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

import oci
from oci.auth.signers import InstancePrincipalsSecurityTokenSigner
from oci.exceptions import ServiceError
from oci.core import ComputeClient

try:
    from kubernetes import client as k8s_client
    from kubernetes import config as k8s_config
    from kubernetes.config.config_exception import ConfigException
except ModuleNotFoundError as exc:
    raise SystemExit(
        "kubernetes package is required. Install with 'pip install kubernetes'."
    ) from exc


COLUMN_MAX_WIDTHS = {
    "CLIQUE": 36,
    "GPU MEMORY CLUSTER": 60,
    "GPU MEMORY FABRIC": 60,
    "RACK": 36,
    "NODES IN CLIQUE": 15,
    "AVAILABLE TO DEPLOY": 18,
}


FABRIC_TO_RACK = {
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycwnfg5zw5h4qplota33m4v3lvcui5whybq5zdy7x7mkna": "sk-4e677e0b-7a35-46e4-a4d6-78b18fcf5ded",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycdsrmp4x2ln42ujtmtorrpjak5ts3fzcdmwbtse24wnea": "sk-211c85e6-ba5b-4a4e-8a33-ca218612fc20",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyc7inoo7s6xw2cauu5vvd4zsq6wnqz5nfw4izvjvd5r52q": "sk-280d3328-2508-48c2-8ac4-592f8e0d309e",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyc5fwrnzfidhs5ufdmd4ht3vvisvrkzrjucw35uiruwi2a": "sk-65179536-f2aa-4b90-9496-ff5c056a21c0",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyc2rf5gna5wdhmkvi4rnnhwa3xezyww6a5kvsnyali5azq": "sk-26334514-645f-45bf-b6c4-93a7643274bc",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyc2dmvffx3hj6kbdiwzykpmi5mdginsi4acupfcfee75jq": "sk-fb43128a-c9d7-491e-9c1d-590f8ae4d5b8",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycy33zajg6hzih5k2uuef34gjiyedhjjjqd2ftborf4qqq": "sk-2b7b1f67-f349-4d29-9cc8-04bedfdf32bf",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycwb5vg4jhwb2fwgrvrxjtnowmw4gbiq7xvbtfgwiclibq": "sk-7cb5990e-9c10-4818-8e99-e685fee5f9a6",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycsvcm7ht253vzwcznpiivzxjewxjippko2b7a52eb5pyq": "sk-07372e59-c18b-4d5a-97a5-776fe8b6f36d",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycp4npvoulonyobdchdb2otqglhbpnwi6dzykshqpxvyxa": "sk-189c29b0-73ee-4a40-b2b7-81a7de48557b",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycjwpjvudm7zpwv33cfnbdlda7sxgjddmmvpvtkj3zctga": "sk-d8d2f63d-7c30-4284-a59a-193575cc9f4a",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycbyg2nomh4qxretrc6bg6gho5dmxph7xhufqtdv2mt5iq": "sk-f4b8cd63-445f-4310-99dd-74453f9ded21",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyc7lzxt7l3wo2qcluekwn2hfe3pawvrhwnumgksveor6bq": "sk-e6df6e21-5b1d-492e-a5b1-145abbbdaa1b",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyczkz5fqbwry5gbk7frn7lo3cxdiko64pvmmzti4zu4kka": "sk-554205bf-f8e3-45c0-90e4-d45ed8b78c12",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivycwrtzjmip45u32vr37k7fsfw2tli6qnz7ivs4mtfznt7q": "sk-61fc26f8-a4bb-472a-9d66-43f3be0530e7",
    "ocid1.computegpumemoryfabric.oc1.ap-sydney-1.anzxsljr2472ivyc4db5tewtvdeewzlev7eucqj6rgadk4theuif4ty775ba": "sk-355dd98e-71f5-43ad-a1c8-caca1b7d1d08",
}


def build_kubernetes_client() -> k8s_client.CoreV1Api:
    """Instantiate a CoreV1Api using in-cluster config or local kubeconfig."""

    try:
        k8s_config.load_incluster_config()
    except ConfigException:
        k8s_config.load_kube_config()
    return k8s_client.CoreV1Api()


def load_node_metadata(api: k8s_client.CoreV1Api) -> Dict[str, List[Tuple[str, str]]]:
    """Return map of clique -> list[(node_name, provider_id)] using Kubernetes API."""

    try:
        response = api.list_node()
    except Exception as exc:
        raise RuntimeError(f"Failed to list Kubernetes nodes: {exc}") from exc

    clique_nodes: Dict[str, List[Tuple[str, str]]] = {}
    for item in response.items:
        metadata = item.metadata or k8s_client.V1ObjectMeta()
        labels = metadata.labels or {}
        clique = labels.get("nvidia.com/gpu.clique")
        spec = item.spec or k8s_client.V1NodeSpec()
        provider_id = spec.provider_id
        if not clique or not provider_id:
            continue
        clique_nodes.setdefault(clique, []).append(
            (metadata.name or "", provider_id)
        )
    return clique_nodes


def build_compute_client() -> ComputeClient:
    """Create a ComputeClient using instance principal authentication."""

    signer = InstancePrincipalsSecurityTokenSigner()
    region = signer.region or os.environ.get("OCI_REGION")
    if not region:
        raise RuntimeError(
            "Unable to determine OCI region for Instance Principals. "
            "Set OCI_REGION environment variable."
        )
    config = {"region": region}
    return ComputeClient(config=config, signer=signer)


def gather_rows(
    compute_client: ComputeClient, api: k8s_client.CoreV1Api
) -> List[Tuple[str, str, str, str, int, int]]:
    """Gather (clique, GPU memory cluster, GPU memory fabric, rack, node count, available hosts) rows."""

    rows: List[Tuple[str, str, str, str, int, int]] = []
    clique_nodes = load_node_metadata(api)

    for clique in sorted(clique_nodes):
        entries = clique_nodes[clique]
        if not entries:
            continue
        node_name, provider_id = sorted(entries, key=lambda item: item[0])[0]

        node_count = len(entries)
        
        try:
            instance = compute_client.get_instance(provider_id).data
        except ServiceError as exc:
            print(
                f"Warning: failed to fetch instance {provider_id} for {node_name}: {exc}",
                file=sys.stderr,
            )
            rows.append((clique, "", "", "", node_count, 0))
            continue

        freeform_tags = instance.freeform_tags or {}
        gmc = freeform_tags.get("oci:compute:gpumemorycluster")
        if not gmc:
            rows.append((clique, "", "", "", node_count, 0))
            continue

        try:
            gmc_details = compute_client.get_compute_gpu_memory_cluster(gmc).data
            gmf = getattr(gmc_details, "gpu_memory_fabric_id", "") or ""
        except ServiceError as exc:
            print(
                f"Warning: failed to fetch GPU memory cluster {gmc}: {exc}",
                file=sys.stderr,
            )
            gmf = ""

        rack = FABRIC_TO_RACK.get(gmf, "")
        
        # Fetch available host count from GPU memory fabric
        available_hosts = 0
        if gmf:
            try:
                gmf_details = compute_client.get_compute_gpu_memory_fabric(gmf).data
                available_hosts = getattr(gmf_details, "available_host_count", 0)
            except ServiceError as exc:
                print(
                    f"Warning: failed to fetch GPU memory fabric {gmf}: {exc}",
                    file=sys.stderr,
                )
        
        rows.append((clique, gmc, gmf, rack, node_count, available_hosts))

    return rows


def format_as_table(rows: Iterable[Tuple[str, str, str, str, int, int]], wrap: bool = False) -> str:
    """Return human-friendly table string."""

    headers = ("CLIQUE", "GPU MEMORY CLUSTER", "GPU MEMORY FABRIC", "RACK", "NODES IN CLIQUE", "AVAILABLE TO DEPLOY")
    rows = list(rows)
    if not wrap:
        widths = [len(header) for header in headers]
        for row in rows:
            for idx, value in enumerate(row):
                widths[idx] = max(widths[idx], len(str(value)))

        header_line = " | ".join(
            header.ljust(widths[idx]) for idx, header in enumerate(headers)
        )
        separator = "-+-".join("-" * width for width in widths)

        lines = [header_line, separator]
        for row in rows:
            line = " | ".join(str(value).ljust(widths[idx]) for idx, value in enumerate(row))
            lines.append(line)
        return "\n".join(lines)

    widths = [
        max(len(header), COLUMN_MAX_WIDTHS.get(header, len(header)))
        for header in headers
    ]

    header_line = " | ".join(
        header.ljust(widths[idx]) for idx, header in enumerate(headers)
    )
    separator = "-+-".join("-" * width for width in widths)

    wrapped_rows = []
    for row in rows:
        wrapped = {}
        for idx, header in enumerate(headers):
            width = widths[idx]
            value = str(row[idx])
            if value:
                lines = textwrap.wrap(
                    value,
                    width=width,
                    break_long_words=True,
                    break_on_hyphens=False,
                )
                if not lines:
                    lines = [""]
            else:
                lines = [""]
            wrapped[header] = lines
        wrapped_rows.append(wrapped)

    lines = [header_line, separator]
    for wrapped in wrapped_rows:
        max_lines = max(len(wrapped[header]) for header in headers)
        for line_idx in range(max_lines):
            parts = []
            for idx, header in enumerate(headers):
                column_lines = wrapped[header]
                text = column_lines[line_idx] if line_idx < len(column_lines) else ""
                parts.append(text.ljust(widths[idx]))
            lines.append(" | ".join(parts))
    return "\n".join(lines)


def write_delimited(
    rows: Iterable[Tuple[str, str, str, str, int, int]],
    headers: Tuple[str, str, str, str, str, str],
    delimiter: str,
    output: Optional[Path] = None,
) -> str:
    """Write rows as CSV/TSV, optionally to file, and return string."""

    buffer = StringIO()
    writer = csv.writer(buffer, delimiter=delimiter)

    writer.writerow(headers)
    for row in rows:
        writer.writerow(row)

    content = buffer.getvalue().strip()
    if output:
        output.write_text(content + "\n", encoding="utf-8")
    return content


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate GPU clique to memory cluster/fabric mapping using OCI SDK."
    )
    parser.add_argument(
        "--format",
        choices=["table", "csv", "tsv"],
        default="table",
        help="Output format (default: table)",
    )
    parser.add_argument(
        "--wrap",
        action="store_true",
        help="Wrap long values in table output.",
    )
    parser.add_argument(
        "--sort-by",
        choices=["nodes", "available"],
        default="nodes",
        help="Sort by NODES IN CLIQUE (nodes) or AVAILABLE TO DEPLOY (available). Default: nodes",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional path to write output file. If omitted, print to stdout.",
    )
    args = parser.parse_args()

    compute_client = build_compute_client()
    k8s_api = build_kubernetes_client()
    rows = gather_rows(compute_client, k8s_api)
    headers = ("CLIQUE", "GPU MEMORY CLUSTER", "GPU MEMORY FABRIC", "RACK", "NODES IN CLIQUE", "AVAILABLE TO DEPLOY")

    # Sort rows based on user preference (descending order)
    if args.sort_by == "nodes":
        rows = sorted(rows, key=lambda r: r[4], reverse=True)
    elif args.sort_by == "available":
        rows = sorted(rows, key=lambda r: r[5], reverse=True)

    if args.format == "table":
        content = format_as_table(rows, wrap=args.wrap)
        if args.output:
            args.output.write_text(content + "\n", encoding="utf-8")
        else:
            print(content)
        return 0

    delimiter = "," if args.format == "csv" else "\t"
    content = write_delimited(rows, headers, delimiter, args.output)
    if not args.output:
        print(content)
    return 0


if __name__ == "__main__":
    sys.exit(main())

