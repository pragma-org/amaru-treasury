ccli() {
  cardano-cli latest "$@" --socket-path "${CARDANO_NODE_SOCKET_PATH}" $(network_id)
}
