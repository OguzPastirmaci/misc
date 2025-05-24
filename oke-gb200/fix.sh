NAMESPACE="nvidia-dra-driver-gpu"
DAEMONSET=$(kubectl get ds -n nvidia-dra-driver-gpu --no-headers | awk '$1 ~ /^nccl-test-compute-domain/ {print $1}')
TMP_FILE=$(mktemp)

kubectl get ds "$DAEMONSET" -n "$NAMESPACE" -o yaml > "$TMP_FILE"

sed -i 's/test "$(nvidia-imex-ctl -q)" = "READY"/test "$(nvidia-imex-ctl -q -i 127.0.0.1 50005)" = "READY"/g' "$TMP_FILE"

kubectl apply -f "$TMP_FILE" -n "$NAMESPACE"

rm "$TMP_FILE"