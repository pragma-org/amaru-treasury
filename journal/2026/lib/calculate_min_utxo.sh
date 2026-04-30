calculate_min_utxo () {
  local addr=$1
  local usdm=$2
  local pparams=$3

  echo $(ccli_ transaction calculate-min-required-utxo --tx-out "$addr+2000000+$usdm $USDM_POLICY.$USDM_TOKEN" --protocol-params-file "$pparams" | cut -d ' ' -f2)
}
