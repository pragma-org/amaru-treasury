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
         ledger: MultisigScript,
         consensus: MultisigScript,
         mercenaries: MultisigScript,
         marketing: MultisigScript,
       }
       ```

       > [!NOTE]
       >
       > A `MultisigScript` is a supercharged native-script that is also
       > capable of holding a script. It is defined and exported by the
       > [`aicone`](https://github.com/SundaeSwap-finance/aicone) library.

- Ensure proper lifecycle of the tracking NFT:
  - trap the token at the script's address when minting;
  - verify the integrity of the datum when minting;
  - allow burning when authorized.

## Parameters

### Registry

1. `seed: OutputReference`: a UTxO to be consumed during minting, ensuring uniqueness of the execution and of the policy id (script hash).

2. `scope: Scope`: a scope (ledger, consensus, mercenaries, marketing) used to define an the minted asset's name. Forcing an extra parameter just for an asset name may seem superfluous but it is necessary to allow having one distinct registry per scope. This way, they can each point to a different treasury script.

### Scopes

1. `seed: OutputReference`: a UTxO to be consumed during minting, ensuring uniqueness of the execution and of the policy id (script hash).
