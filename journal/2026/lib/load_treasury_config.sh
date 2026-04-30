load_treasury_config() {
  local metadata=$1
  local scope=$2
  owner_credential=$(echo "${metadata}" | jq -r ".treasuries.${scope}.owner")
  treasury_script_hash=$(echo "${metadata}" | jq -r ".treasuries.${scope}.treasury_script.hash")
  treasury_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.treasury_script.deployed_at")
  registry_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.registry_script.deployed_at")
  treasury_address=$(address_from_script_hash "$treasury_script_hash")
  treasury_stake_address=$(stake_address_from_script_hash "$treasury_script_hash")

  key_value "$COL" "network" "$(network_tag)"
  key_value "$COL" "owner.credential" "$owner_credential"
  key_value "$COL" "treasury.script_hash" "$treasury_script_hash"
  key_value "$COL" "treasury.stake_address" "$treasury_stake_address"
  key_value "$COL" "treasury.address" "$treasury_address"
  key_value "$COL" "treasury.reference" "$treasury_reference"
  key_value "$COL" "registry.reference" "$registry_reference"
}
