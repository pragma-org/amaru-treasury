resolve_fuel() {
  local wallet_address="$1"
  local fuel_cache="/tmp/${wallet_address}.utxo"

  if [[ -z "${FORCE_NEW_FUEL:-}" ]]; then
    if [[ -z "${FUEL:-}" && -f "$fuel_cache" ]]; then
      export FUEL
      FUEL=$(cat "$fuel_cache")
    fi

    if [[ -n "${FUEL:-}" ]]; then
      echo -e "  \033[0;33m(re-using cached fuel UTxO; to force a new one, set \033[1;33mFORCE_NEW_FUEL=1)\033[0m" >&2
    fi
  fi

  if [[ -z "${FUEL:-}" ]]; then
    FUEL=$(\
      ccli query utxo --address "$wallet_address" --output-json | \
	jq -rc '. | keys | @csv' | \
	tr ',' '\n' | \
	tr -d '"' | \
	head -1 \
    )
  fi

  echo "$FUEL" > "$fuel_cache"
  key_value "$COL" "wallet.utxo" "$FUEL"
  echo $FUEL
}
