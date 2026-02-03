### Configuration

# The target network for which to build and mint initial configuration.
NETWORK ?= preview

# A (spendable) UTxO reference to seed the scopes.
#
# Must have enough ADA to cover for the transaction fee (~0.3 ADA) and the
# min-UTxO deposit that will hold the scopes datum (2 ADA)
SCOPES_SEED_TX ?= 6be590477b9338f840a1c27c6990e091e1ef96ead4c8f27b62b8964fb01450a2
SCOPES_SEED_IX ?= 01

# A (spendable) UTxO reference to seed the treasury registries.
#
# Must have enough ADA to cover for the transaction fee (~0.75 ADA) and the
# min-UTxO deposits that will hold each registry (2 ADA x 5 = 10 ADA).
REGISTRY_SEED_TX ?= 5836e1b87e0e7e9d9bac9bba1ea93fcc9afca79433e42367db864f879a1aee12
REGISTRY_SEED_IX ?= 05

# The public key hash of the (initial) core_development scope owner
OWNER_CORE_DEVELOPMENT ?= 7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb
# The public key hash of the (initial) ops_and_use_cases scope owner
OWNER_OPS_AND_USE_CASES ?= 6db01d01e6fe2b770eea422f0323f7425ef727e487a817ac2d752a9a
# The public key hash of the (initial) network_compliance scope owner
OWNER_NETWORK_COMPLIANCE ?= 6db01d01e6fe2b770eea422f0323f7425ef727e487a817ac2d752a9a
# The public key hash of the (initial) middleware scope owner
OWNER_MIDDLEWARE ?= 70b46e985fa50328fcb3d80594b6c5c54974a08d2c766a47570bfa36

OWNERS := $(OWNER_CORE_DEVELOPMENT) $(OWNER_OPS_AND_USE_CASES) $(OWNER_NETWORK_COMPLIANCE) $(OWNER_MIDDLEWARE)

.PHONY: help scopes permissions treasury registry

help:
	@echo "\033[1;4mProcedure:\033[00m"
	@echo "  scopes → permissions → treasury → registry"
	@echo ""
	@echo "\033[1;4mRecipes:\033[00m"
	@grep -E '^[%a-zA-Z0-9 -]+:.*##'  Makefile | sed "s/%/%%/" | while read -r l; do printf "  \033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 3- -d'#')\n"; done
	@echo ""
	@echo "\033[1;4mConfiguration:\033[00m"
	@grep -E '^[a-zA-Z0-9_]+ \?= '  Makefile | while read -r l; do printf "  \033[36m$$(echo $$l | cut -f 1 -d'=')\033[00m=$$(echo $$l | cut -f 2- -d'=')\n"; done

scopes: prerequisites ## Compile the scopes script, and prepare its initial minting transaction.
	@recipes/scopes.sh $(NETWORK) $(SCOPES_SEED_TX) $(SCOPES_SEED_IX) $(OWNERS)

permissions: permissions-core_development permissions-ops_and_use_cases permissions-network_compliance permissions-middleware permissions-contingency ## Compile all permissions scripts for all scopes.

permissions-%: prerequisites ## Compile the permissions script for a single scope.
	@recipes/permissions.sh $(NETWORK) $*

treasury: treasury-core_development treasury-ops_and_use_cases treasury-network_compliance treasury-middleware treasury-contingency ## Compile all teasury scripts for all scopes.

treasury-%: prerequisites ## Compile the treasury script for a single scope.
	@recipes/treasury.sh $(NETWORK) $* $(REGISTRY_SEED_TX) $(REGISTRY_SEED_IX)

registry: prerequisites ## Construct a minting transaction for all treasury registries.
	@recipes/registry.sh $(NETWORK) $(REGISTRY_SEED_TX) $(REGISTRY_SEED_IX)

clean: ## Remove temporary build artifacts.
	rm -f build/*.json
	rm -f build/*.hash
	rm -f build/*.cbor

prerequisites:
	@command -v aiken 1>/dev/null || (echo "missing required tool: 'aiken'" && exit 1)
	@command -v cardano-cli 1>/dev/null || (echo "missing required tool: 'cardano-cli'" && exit 1)
	@command -v jq 1>/dev/null || (echo "missing required tool: 'jq'" && exit 1)
	@command -v basenc 1>/dev/null || (echo "missing required tool: 'basenc'" && exit 1)
