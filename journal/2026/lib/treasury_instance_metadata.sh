treasury_instance_metadata() {
  local registry_reference="$1"
  treasury_instance=$( \
    ccli query utxo --tx-in "$registry_reference" --output-json | \
    jq -r -c '.[keys[0]].value | keys[0]' \
  )
  tmp=$(mktemp)
  jq ".[\"1694\"].instance = \"$treasury_instance\"" "$RATIONALE_JSON" > "$tmp"
  echo $tmp
}
