#!/bin/bash

echo "Tearing down HELMS"

RELEASES=(reader front back kafka postgres)
NAMESPACES=(demo-reader demo-front demo-back kafka postgres)

for i in "${!RELEASES[@]}"; do
  release="${RELEASES[$i]}"
  ns="${NAMESPACES[$i]}"
  echo "Uninstalling $release from $ns..."
  helm uninstall "$release" -n "$ns" 2>/dev/null && echo "$release removed" || echo "$release not found"
done

echo ""
echo "Deleting namespaces..."
for ns in "${NAMESPACES[@]}"; do
  kubectl delete namespace "$ns" --ignore-not-found
done

echo ""
echo "Done"