address_from_script_hash() {
  [[ $# -eq 1 ]] || { echo "expect one script hash argument" >&2; exit 1; }
  local hash address_no_stake
  hash=$(echo -n "$1" | bech32 script)
  address_no_stake=$(echo -n "$hash" | cardano-address address payment --network-tag "$(network_tag)")
  echo -n "$address_no_stake" | cardano-address address delegation "$hash"
}
