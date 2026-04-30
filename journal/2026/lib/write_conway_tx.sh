write_conway_tx() {
  local tx_file="$1"
  local prefix="$2"

  tx_id=$(ccli_ transaction txid --tx-file "$tx_file" --output-text)
  out="$prefix-${scope}-${tx_id:0:12}.cbor.json"
  jq '.type = "Tx ConwayEra"' "$tx_file" > "$out"

  key_value "$COL" "transaction.id" "$tx_id"
  key_value "$COL" "transaction.file" "$out"
}
