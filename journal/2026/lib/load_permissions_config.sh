load_permissions_config() {
  local metadata=$1
  local scope=$2
  permissions_script_hash=$(echo "${metadata}" | jq -r ".treasuries.${scope}.permissions_script.hash")
  permissions_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.permissions_script.deployed_at")
  scopes_reference=$(echo "${metadata}" | jq -r ".scope_owners")
  permissions_stake_address=$(stake_address_from_script_hash "$permissions_script_hash")
  key_value "$COL" "permissions.script_hash" "$permissions_script_hash"
  key_value "$COL" "permissions.address" "$permissions_stake_address"
  key_value "$COL" "permissions.reference" "$permissions_reference"
  key_value "$COL" "scopes.reference" "$scopes_reference"
}
