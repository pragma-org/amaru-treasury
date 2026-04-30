network_id() {
  case "${CARDANO_NODE_NETWORK_ID}" in
    0|764824073) echo -n "--mainnet" ;;
    *) echo -n "--testnet-magic ${CARDANO_NODE_NETWORK_ID}" ;;
  esac
}
