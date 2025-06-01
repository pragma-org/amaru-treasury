# Amaru Treasury Contract(s)

## Getting Started

### Pre-requisites

- aiken >= v1.1.17
- cardano-cli >= 10.4.0.0
- jq >= 1.5
- (optional) ogmios >= v6.10.0

### Configuring

#### Validators

See [aiken.toml](./aiken.toml)

#### Makefile

See [Makefile](./Makefile).

### Running

> [!TIP]
>
> At any time, to get a friendly reminder of the configuration and commands, just run:
>
> ```console
> make help
> ```

1. `make scopes`

   This initialize the scope owners (from the Makefile's configuration) and prepare a minting transaction to publish them on-chain.
   The transaction must be signed and submitted through your own means.

2. `make permissions`

   Build each _permissions_ validators, each used to manage a treasury.

3. `make treasury`

   Build each _treasury_ validators as well as their corresponding registries.

4. `make registry`

   Prepare a minting transaction to publish all registries on-chain.
   The transaction must be signed and submitted through your own means.
