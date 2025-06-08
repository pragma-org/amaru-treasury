#!/usr/bin/env bash

# Copyright 2025 PRAGMA
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -euo pipefail
source recipes/shared.sh

show_usage() {
  cat <<EOF
Usage: ${0##*/} [NETWORK] [SCOPE]

Arguments:
  NETWORK      Target network (preview | mainnet)
  SCOPE        Which scope to create permissions for (ledger, consensus, mercenaries, marketing or contingency)

Example:
  ${0##*/} preview ledger 5bc659e149349b7d1d23493c7b7276a2ac83ad07c4249c125d3b1f49
EOF
}

trap 'ret=$?; if (( ret != 0 )); then show_usage; fi' EXIT

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

SCOPE=${2:-}
fail_when_missing "SCOPE" ${SCOPE:-}
SCOPE_CONSTR=$(scope_to_constr $SCOPE)

SCOPES_HASH=$(jq -r ".validators[0].hash" build/scopes.plutus.json)
fail_when_missing "SCOPES_HASH" ${SCOPES_HASH:-}

aiken build -D --env $ENV
step "Applying" "parameters"
step "Scopes Hash" $SCOPES_HASH
step "Scope" $SCOPE

TMP=$(mktemp)
aiken blueprint apply -v permissions -o $TMP "581c$SCOPES_HASH"
BLUEPRINT=$(aiken blueprint apply -i $TMP -v permissions $SCOPE_CONSTR)
VALIDATOR=$(echo $BLUEPRINT | jq -r '.validators[] | select(.title=="permissions.permissions.withdraw")')
HASH=$(echo $VALIDATOR | jq -r '.hash')
step "Hash" $HASH
step "Size" "$(script_size "$VALIDATOR") bytes"
OUT="build/permissions-$SCOPE.plutus.json"
echo $BLUEPRINT | \
  jq '.validators = ([.validators[] | select(.title=="permissions.permissions.withdraw")])' | \
  jq ".validators[0].title = \"permissions~1$SCOPE\"" > $OUT
step "Saved as" $OUT
echo "" >&2
