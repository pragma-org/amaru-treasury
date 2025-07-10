//// Copyright 2025 PRAGMA
////
//// Licensed under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License.
//// You may obtain a copy of the License at
////
////     http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software
//// distributed under the License is distributed on an "AS IS" BASIS,
//// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//// See the License for the specific language governing permissions and
//// limitations under the License.

use aiken/cbor
use aiken/crypto.{VerificationKeyHash}
use aiken/primitive/bytearray
use cardano/assets.{PolicyId}
use cardano/transaction.{Datum, Input, Transaction}
use config
use sundae/multisig.{MultisigScript}

pub type Scope {
  Ledger
  Consensus
  Mercenaries
  Marketing
  Contingency
}

/// A dynamic scopes definition to be stored on-chain (inline datum). Note that
/// the contingency scope governing rules are derived from the others.
pub type Scopes {
  ledger: MultisigScript,
  consensus: MultisigScript,
  mercenaries: MultisigScript,
  marketing: MultisigScript,
}

/// Define the default scopes for bootstrapping the state. This function is used by
/// the surrounding tooling to easily get a binary representation of the initial datum.
pub fn export_scopes(
  ledger: VerificationKeyHash,
  consensus: VerificationKeyHash,
  mercenaries: VerificationKeyHash,
  marketing: VerificationKeyHash,
) {
  expect bytearray.length(ledger) == 28
  expect bytearray.length(consensus) == 28
  expect bytearray.length(mercenaries) == 28
  expect bytearray.length(marketing) == 28

  cbor.serialise(
    Scopes {
      ledger: multisig.Signature(ledger),
      consensus: multisig.Signature(consensus),
      mercenaries: multisig.Signature(mercenaries),
      marketing: multisig.Signature(marketing),
    },
  )
}

/// Assert (or fail) that a given datum is inline and has an expected shape; returning the Scopes.
pub fn with_inline_scopes(datum: Datum, return: fn(Scopes) -> result) -> result {
  expect Datum.InlineDatum(data) = datum
  expect scopes: Scopes = data
  return(scopes)
}

/// Assert (or fail) that a given datum is inline and has an expected shape.
pub fn expect_inline_scopes(datum: Datum) -> Bool {
  with_inline_scopes(datum, fn(_) { True })
}

/// Look for an input holding a scopes NFT, and return the held `Scopes`.
pub fn expect_scopes(inputs: List<Input>, policy_id: PolicyId) -> Scopes {
  when inputs is {
    [] -> {
      trace @"no scopes found in reference inputs for policy id": policy_id
      fail
    }
    [head, ..tail] ->
      if assets.quantity_of(
        head.output.value,
        policy_id,
        config.scopes_token_name,
      ) == 1 {
        with_inline_scopes(head.output.datum, identity)
      } else {
        expect_scopes(tail, policy_id)
      }
  }
}

/// A more permissive version that approves an operation if authenticated by the given scope owner.
pub fn approved_by_owner(
  self: Transaction,
  scope: Scope,
  scopes: Scopes,
) -> Bool {
  multisig.satisfied(
    when scope is {
      Ledger -> scopes.ledger
      Consensus -> scopes.consensus
      Mercenaries -> scopes.mercenaries
      Marketing -> scopes.marketing
      Contingency ->
        multisig.AnyOf(
          [
            scopes.ledger,
            scopes.consensus,
            scopes.mercenaries,
            scopes.marketing,
          ],
        )
    },
    self.extra_signatories,
    self.validity_range,
    self.withdrawals,
  )
}

/// Checks that the operation is allowed by the current scope owner, but also by
/// *another* scope owner. We leverage the fact that they're all Multisig
/// scripts, and thus can be combined into one. If the script execution become
/// too expensive, we could write a more specialized version (e.g. passing as
/// redeemer what's the expected other).
pub fn approved_by_owner_and_someone_else(
  self: Transaction,
  scope: Scope,
  scopes: Scopes,
) -> Bool {
  multisig.satisfied(
    when scope is {
      Ledger ->
        multisig.AllOf(
          [
            scopes.ledger,
            multisig.AnyOf(
              [scopes.consensus, scopes.mercenaries, scopes.marketing],
            ),
          ],
        )
      Consensus ->
        multisig.AllOf(
          [
            scopes.consensus,
            multisig.AnyOf(
              [scopes.ledger, scopes.mercenaries, scopes.marketing],
            ),
          ],
        )
      Mercenaries ->
        multisig.AllOf(
          [
            scopes.mercenaries,
            multisig.AnyOf([scopes.ledger, scopes.consensus, scopes.marketing]),
          ],
        )
      Marketing ->
        multisig.AllOf(
          [
            scopes.marketing,
            multisig.AnyOf(
              [scopes.ledger, scopes.consensus, scopes.mercenaries],
            ),
          ],
        )
      Contingency ->
        multisig.AllOf(
          [
            scopes.ledger,
            scopes.consensus,
            scopes.mercenaries,
            scopes.marketing,
          ],
        )
    },
    self.extra_signatories,
    self.validity_range,
    self.withdrawals,
  )
}
