# Permissions

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../.github/img/permissions-state-diagram-dark.svg" />
  <source media="(prefers-color-scheme: light)" srcset="../.github/img/permissions-state-diagram-light.svg" />
  <img alt="State diagram" src="../.github/img/permissions-state-diagram-dark.svg" height="200" />
</picture>

## Functionality

- Authorize management of a specific treasury by a (dynamic) scope owner.

  With the exception of the _contingency_ scope:

  - the `reorganize` operation can be performed by the scope owner alone;
  - the `sweep` and `disburse` operations require the scope owner and at least _another_ scope owner;

  The _contingency_ scope, on the other hand, is managed as follows:

  - any scope owner can perform the `reorganize` operation on the _contingency_ treasury;
  - ALL scope owners must approve of a `sweep` or `disburse` of the _contingency_ treasury.

- The validator also permits the scope owner to perform normal spend or publish
  operations. In practice, this isn't needed because the script shall only live
  as stake credential, but in case where it would be misused as an address,
  then it is _as if_ it belonged to the scope owner.

- The credentials for each scope owner are defined _dynamically_ and attached
  to a UTxO that carries a well-known NFT. Credentials aren't baked into the
  validator, so, a reference input holding the _scopes_ definitions is required
  to authenticate operations.

## Parameters

1. `scopes_nft: PolicyId`: The policy-id / script hash of the _scopes_ script managing the scopes definitions. This is the script controlled by PRAGMA, which defines who are effectively the scope owners for each scope.

2. `scope: Scope`: The actual scope (ledger, consensus, mercenaries, marketing or contingency) for that validator.
