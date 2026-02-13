### Configuration

# The target network for which to build and mint initial configuration.
NETWORK ?= mainnet

# A (spendable) UTxO reference to seed the scopes.
#
# Must have enough ADA to cover for the transaction fee (~0.3 ADA) and the
# min-UTxO deposit that will hold the scopes datum (2 ADA)
SCOPES_SEED_TX ?= 2d8871c264e32bef3ad728738beba5a8b4c78edccaf51e8c3ab693ff697f21fc
SCOPES_SEED_IX ?= 00

# A (spendable) UTxO reference to seed the treasury registries.
#
# Must have enough ADA to cover for the transaction fee (~0.75 ADA) and the
# min-UTxO deposits that will hold each registry (2 ADA x 5 = 10 ADA).
REGISTRY_SEED_TX ?= 80ac843c71d5c4933877ab671bf377b34bc90abfc4df8287a3e92af806152c48
REGISTRY_SEED_IX ?= 00

# The public key hash of the (initial) core_development scope owner
OWNER_CORE_DEVELOPMENT ?= 7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb
# The public key hash of the (initial) ops_and_use_cases scope owner
OWNER_OPS_AND_USE_CASES ?= f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e
# The public key hash of the (initial) network_compliance scope owner
OWNER_NETWORK_COMPLIANCE ?= 8bd03209d227956aaf9670751e0aa2057b51c1537a43f155b24fb1c1
# The public key hash of the (initial) middleware scope owner
OWNER_MIDDLEWARE ?= 97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2

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
	@recipes/register-permissions-scripts.sh $(NETWORK)
	@recipes/publish-permissions-scripts.sh $(NETWORK)

permissions-%: prerequisites ## Compile the permissions script for a single scope.
	@recipes/permissions.sh $(NETWORK) $*

treasury: treasury-core_development treasury-ops_and_use_cases treasury-network_compliance treasury-middleware treasury-contingency ## Compile all teasury scripts for all scopes.
	@recipes/register-treasury-scripts.sh $(NETWORK)
	@recipes/publish-treasury-scripts.sh $(NETWORK) core_development
	@recipes/publish-treasury-scripts.sh $(NETWORK) ops_and_use_cases
	@recipes/publish-treasury-scripts.sh $(NETWORK) network_compliance
	@recipes/publish-treasury-scripts.sh $(NETWORK) middleware
	@recipes/publish-treasury-scripts.sh $(NETWORK) contingency

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
