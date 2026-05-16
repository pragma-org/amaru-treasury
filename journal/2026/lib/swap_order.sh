swap_order() {
  local chunk_lovelace="$1"
  local rate="$2"
  local metadata="$3"
  local treasury_script_hash="$4"
  local chunk_usdm
  local tmp_datum

  chunk_usdm=$(awk "BEGIN {print ($chunk_lovelace * $rate)}")
  tmp_datum=$(mktemp)

  cat > "$tmp_datum" <<EOF
{
  "constructor": 0,
  "fields": [
    { "constructor": 0, "fields": [{ "bytes": "$SUNDAE_USDM_POOL" }] },
    {
      "constructor": 3,
      "fields": [
        { "int": 2 },
        {
          "list": [
            { "constructor": 0, "fields": [ { "bytes": "$(echo "$metadata" | jq -cr ".treasuries.core_development.owner")" } ] },
            { "constructor": 0, "fields": [ { "bytes": "$(echo "$metadata" | jq -cr ".treasuries.ops_and_use_cases.owner")" } ] },
            { "constructor": 0, "fields": [ { "bytes": "$(echo "$metadata" | jq -cr ".treasuries.network_compliance.owner")" } ] },
            { "constructor": 0, "fields": [ { "bytes": "$(echo "$metadata" | jq -cr ".treasuries.middleware.owner")" } ] }
          ]
        }
      ]
    },
    { "int": $SUNDAE_PROTOCOL_FEE_LOVELACE },
    {
      "constructor": 0,
      "fields": [
        {
          "constructor": 0,
          "fields": [
            { "constructor": 1, "fields": [ { "bytes": "$treasury_script_hash" } ] },
            {
              "constructor": 0,
              "fields": [{
                "constructor": 0,
                "fields": [{ "constructor": 1, "fields": [ { "bytes": "$treasury_script_hash" } ] }]
              }]
            }
          ]
        },
        { "constructor": 0, "fields": [] }
      ]
    },
    {
      "constructor": 1,
      "fields": [
        { "list": [ { "bytes": "" }, { "bytes": "" }, { "int": $chunk_lovelace } ] },
        { "list": [ { "bytes": "$USDM_POLICY" }, { "bytes": "$USDM_TOKEN" }, { "int": $chunk_usdm } ] }
      ]
    },
    { "constructor": 0, "fields": [] }
  ]
}
EOF

  echo "$tmp_datum"
}
