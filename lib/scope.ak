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
  CoreDevelopment
  OpsAndUseCases
  NetworkCompliance
  Middleware
  Contingency
}

/// A dynamic scopes definition to be stored on-chain (inline datum). Note that
/// the contingency scope governing rules are derived from the others.
pub type Scopes {
  core_development: MultisigScript,
  ops_and_use_cases: MultisigScript,
  network_compliance: MultisigScript,
  middleware: MultisigScript,
}

/// Define the default scopes for bootstrapping the state. This function is used by
/// the surrounding tooling to easily get a binary representation of the initial datum.
pub fn export_scopes(
  core_development: VerificationKeyHash,
  ops_and_use_cases: VerificationKeyHash,
  network_compliance: VerificationKeyHash,
  middleware: VerificationKeyHash,
) {
  expect bytearray.length(core_development) == 28
  expect bytearray.length(ops_and_use_cases) == 28
  expect bytearray.length(network_compliance) == 28
  expect bytearray.length(middleware) == 28

  cbor.serialise(
    Scopes {
      core_development: multisig.Signature(core_development),
      ops_and_use_cases: multisig.Signature(ops_and_use_cases),
      network_compliance: multisig.Signature(network_compliance),
      middleware: multisig.Signature(middleware),
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
      CoreDevelopment -> scopes.core_development
      OpsAndUseCases -> scopes.ops_and_use_cases
      NetworkCompliance -> scopes.network_compliance
      Middleware -> scopes.middleware
      Contingency ->
        multisig.AnyOf(
          [
            scopes.core_development,
            scopes.ops_and_use_cases,
            scopes.network_compliance,
            scopes.middleware,
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
      CoreDevelopment ->
        multisig.AllOf(
          [
            scopes.core_development,
            multisig.AnyOf(
              [
                scopes.ops_and_use_cases,
                scopes.network_compliance,
                scopes.middleware,
              ],
            ),
          ],
        )
      OpsAndUseCases ->
        multisig.AllOf(
          [
            scopes.ops_and_use_cases,
            multisig.AnyOf(
              [
                scopes.core_development,
                scopes.network_compliance,
                scopes.middleware,
              ],
            ),
          ],
        )
      NetworkCompliance ->
        multisig.AllOf(
          [
            scopes.network_compliance,
            multisig.AnyOf(
              [
                scopes.core_development,
                scopes.ops_and_use_cases,
                scopes.middleware,
              ],
            ),
          ],
        )
      Middleware ->
        multisig.AllOf(
          [
            scopes.middleware,
            multisig.AnyOf(
              [
                scopes.core_development,
                scopes.ops_and_use_cases,
                scopes.network_compliance,
              ],
            ),
          ],
        )
      Contingency ->
        multisig.AllOf(
          [
            scopes.core_development,
            scopes.ops_and_use_cases,
            scopes.network_compliance,
            scopes.middleware,
          ],
        )
    },
    self.extra_signatories,
    self.validity_range,
    self.withdrawals,
  )
}
