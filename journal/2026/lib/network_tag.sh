network_tag() {
  case "${CARDANO_NODE_NETWORK_ID}" in
    0|764824073) echo -n "mainnet" ;;
    1) echo -n "preprod" ;;
    2) echo -n "preview" ;;
    *) echo "unknown network" >&2; exit 1 ;;
  esac
}
