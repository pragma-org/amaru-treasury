make_redeemer_disburse() {
  local unit=$1

  tmp=$(mktemp)

  if [[ "$unit" = "ada" ]]; then
    jq --null-input "{ constructor: 3, fields: [ { map: [ { k: {bytes: \"\"}, v: { map: [{k: {bytes: \"\"}, v : {int: ${amount_lovelace} } } ] } }]}]}" > "$tmp"
  elif [[ "$unit" = "usdm" ]]; then
    jq --null-input "{ constructor: 3, fields: [ { map: [ { k: {bytes: \"$USDM_POLICY\"}, v: { map: [{k: {bytes: \"$USDM_TOKEN\"}, v : {int: ${amount_usdm} } } ] } }]}]}" > "$tmp"
  else
    echo "unrecognized unit; expected either 'ada' or 'usdm'" >&2
    exit 1
  fi

  echo $tmp
}
