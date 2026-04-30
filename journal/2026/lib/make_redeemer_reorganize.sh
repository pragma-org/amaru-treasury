make_redeemer_reorganize() {
  tmp=$(mktemp)
  jq --null-input "{ constructor: 0, fields: [] }" > "$tmp"
  echo "$tmp"
}
