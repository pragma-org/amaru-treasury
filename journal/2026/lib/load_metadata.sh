load_metadata() {
  cat "$(dirname "$0")/../metadata.json" | jq -c
}
