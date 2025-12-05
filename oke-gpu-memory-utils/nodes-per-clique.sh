(
  echo -en "\nNUMBER_OF_RACKS\t"
  kubectl get nodes -o json | jq '[.items[].metadata.labels["nvidia.com/gpu.clique"]] | map(select(. != null)) | unique | length'
  
  echo -e "---\t---"

  echo -e "GPU_CLIQUE_LABEL\tNODE_COUNT"

  kubectl get nodes -o json | jq -r '
    [.items[] | .metadata.labels["nvidia.com/gpu.clique"] // "unlabeled"]
    | group_by(.) 
    | map({label: .[0], count: length}) 
    | sort_by(-.count)
    | .[] 
    | "\(.label)\t\(.count)"
  '
) | column -t
