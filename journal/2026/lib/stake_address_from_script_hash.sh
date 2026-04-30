stake_address_from_script_hash() {
  [[ $# -eq 1 ]] || { echo "expect one script hash argument" >&2; exit 1; }
  local hash
  hash=$(echo -n "$1" | bech32 script)
  echo -n "$hash" | cardano-address address stake --network-tag "$(network_tag)"
}
