# Traps (registry & scopes)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../.github/img/traps-state-diagram-dark.svg" />
  <source media="(prefers-color-scheme: light)" srcset="../.github/img/traps-state-diagram-light.svg" />
  <img alt="State diagram" src="../.github/img/traps-state-diagram-dark.svg" height="200" />
</picture>

## Functionality

- Manage a state (inline datum) identified by an NFT:
  - the exact state depends on how the validator is instantiated. We currently recognize the following states:

    1. `Registry`: used by the treasury validator to identify treasury and vendor scripts.

       ```aiken
       pub type Registry {
         treasury: Credential,
         vendor: Credential,
       }
       ```

    2. `Scopes`: used to administer the scope owners for each permissions validator.

       ```aiken
       pub type Scopes {
         core_development: MultisigScript,
         ops_and_use_cases: MultisigScript,
         network_compliance: MultisigScript,
         middleware: MultisigScript,
       }
       ```

- Ensure proper lifecycle of the tracking NFT:
  - trap the token at the script's address when minting;
  - verify the integrity of the datum when minting;
  - allow burning when authorized and after the agreen-upon expiration date.

> [!NOTE]
>
> A `MultisigScript` is a supercharged native-script that is also capable of
> deferring logic to a script. It is defined and exported by the
> [`aicone`](https://github.com/SundaeSwap-finance/aicone) library.

## Parameters

### Registry

1. `seed: OutputReference`: a UTxO to be consumed during minting, ensuring uniqueness of the execution and of the policy id (script hash).

2. `scope: Scope`: a scope (core development, ops and use cases, network compliance, middleware or contingency) used to define an the minted asset's name. Forcing an extra parameter just for an asset name may seem superfluous but it is necessary to allow having one distinct registry per scope. This way, they can each point to a different treasury script.

Unlike the `Scopes` trap, the registry cannot be updated to different values once it has been created.

### Scopes

1. `seed: OutputReference`: a UTxO to be consumed during minting, ensuring uniqueness of the execution and of the policy id (script hash).
