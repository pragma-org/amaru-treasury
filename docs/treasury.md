# Treasury

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../.github/img/treasury-state-diagram-dark.svg" />
  <source media="(prefers-color-scheme: light)" srcset="../.github/img/treasury-state-diagram-light.svg" />
  <img alt="State diagram" src="../.github/img/treasury-state-diagram-dark.svg" height="200" />
</picture>

## Functionality

Coming soon.

## Parameters

1. `config: TreasuryConfiguration`: hard-wired parameters such as the registry script hash, and the set of permissions scripts.

   ```aiken
   pub type TreasuryConfiguration {
     // The token used to authenticate the script hash registry
     registry_token: PolicyId,
     // The permissions required for different options
     permissions: TreasuryPermissions,
     // The time after which the funds can be swept back to the treasury
     expiration: Int,
     // The upper bound for any payouts created by the oversight committee
     payout_upperbound: Int,
   }
   ```

   > [!NOTE]
   >
   > 1. For the first Amaru withdrawal, the `expiration` date is set to the 31st of December 2025, 23:59:59.
   >
   > 2. We set the `payout_upperbound` to `0` since this is only used in the (unused) `fund` action.
