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

use aiken/builtin
use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Credential, Script}
use cardano/assets.{AssetName, PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Datum, Input, Output, OutputReference, Transaction}
use config
use registry.{Registry, with_inline_registry}
use scope.{Scope, Scopes, with_inline_scopes}
use sundae/multisig

const admin =
  config.pragma_general_assembly
    |> list.map(multisig.Signature)
    |> multisig.AllOf

/// A validator for managing Amaru's scope owners. This is done by PRAGMA General Assembly.
///
/// Fundamentally, this is a trap-like contract, which manages an NFT (used by other contracts
/// to locate the state), and a state attached to the same UTxO that owns the state.
validator scopes(seed: OutputReference) {
  spend(
    _datum: Option<Data<Scopes>>,
    _redeemer: Data,
    utxo: OutputReference,
    self: Transaction,
  ) {
    expect must_be_approved_by_general_assembly(self)

    let output =
      forwarding_output(
        resolve_input(self.inputs, utxo).address.payment_credential,
        config.scopes_token_name,
        self.outputs,
      )

    with_inline_scopes(output.datum, fn(_) { True })?
  }

  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    or {
      mint_one(
        seed,
        policy_id,
        config.scopes_token_name,
        with_inline_scopes(_, fn(_) { True }),
        self,
      )?,
      burn_one(policy_id, config.scopes_token_name, self)?,
    }
  }

  // Allow other types of operations (e.g. stake delegation) at the
  // discretion of the general assembly. This should be mostly useless in
  // practice but prevent from being stuck in undesirable situations.
  else(ctx: ScriptContext) {
    must_be_approved_by_general_assembly(ctx.transaction)?
  }
}

/// A validator for managing the treasury's registry. It is artificially parameterized by a 'Scope'
/// to allow defining multiple policies: one per scope (since each treasury needs its registry).
///
/// Fundamentally, this is a trap-like contract, which manages an NFT (used by other contracts
/// to locate the state), and a state attached to the same UTxO that owns the state.
validator treasury_registry(seed: OutputReference, scope: Scope) {
  spend(
    _datum: Option<Data<Registry>>,
    _redeemer: Data,
    utxo: OutputReference,
    self: Transaction,
  ) {
    expect must_be_approved_by_general_assembly(self)

    let output =
      forwarding_output(
        resolve_input(self.inputs, utxo).address.payment_credential,
        scope.to_bytearray(scope),
        self.outputs,
      )

    with_inline_registry(output.datum, fn(_) { True })?
  }

  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    let asset_name = scope.to_bytearray(scope)
    or {
      mint_one(
        seed,
        policy_id,
        asset_name,
        with_inline_registry(_, fn(_) { True }),
        self,
      )?,
      burn_one(policy_id, asset_name, self)?,
    }
  }

  // Allow other types of operations (e.g. stake delegation) at the
  // discretion of the general assembly. This should be mostly useless in
  // practice but prevent from being stuck in undesirable situations.
  else(ctx: ScriptContext) {
    must_be_approved_by_general_assembly(ctx.transaction)?
  }
}

/// Ensures a transaction is properly authenticated by the admin credentials (i.e. the GA).
pub fn must_be_approved_by_general_assembly(tx: Transaction) -> Bool {
  multisig.satisfied(
    admin,
    tx.extra_signatories,
    tx.validity_range,
    tx.withdrawals,
  )
}

/// Find the output corresponding to an output reference in a list of input.
///
/// Fails when no matching output is found.
fn resolve_input(inputs: List<Input>, utxo_ref: OutputReference) -> Output {
  when inputs is {
    [] -> fail
    [head, ..tail] ->
      if head.output_reference == utxo_ref {
        head.output
      } else {
        resolve_input(tail, utxo_ref)
      }
  }
}

/// Find the output (if any), that forward the state from an original input.
fn forwarding_output(
  destination: Credential,
  asset_name: AssetName,
  outputs: List<Output>,
) -> Output {
  when outputs is {
    [] -> {
      trace @"missing forwarding output": destination
      fail
    }
    [head, ..tail] -> {
      let to_script = head.address.payment_credential == destination
      let has_token =
        fn() {
          expect Credential.Script(policy_id) = destination
          assets.quantity_of(head.value, policy_id, asset_name) == 1
        }
      if to_script && has_token() {
        // We need not to check for the tail here because the token is guaranteed to be unique.
        // Thus, it cannot be found in more than one output. We can stop at the first one.
        head
      } else {
        forwarding_output(destination, asset_name, tail)
      }
    }
  }
}

fn mint_one(
  seed: OutputReference,
  policy_id: PolicyId,
  asset_name: AssetName,
  expect_datum: fn(Datum) -> Bool,
  self: Transaction,
) {
  // Ensure uniqueness by claiming an output reference; this ensures
  // other checks are sound since minting can only happen once.
  let must_spend_seed_utxo =
    self.inputs
      |> list.any(fn(input) { input.output_reference == seed })

  // Ensure the token is trapped by the script. We can filter and only count
  // outputs to our credentials because we also ensure that only one token can
  // be minted.
  // Hence, we need not to check other outputs.
  let must_trap_token =
    self.outputs
      |> list.reduce(
          0,
          fn(sum, output) {
            if output.address.payment_credential == Script(policy_id) {
              expect expect_datum(output.datum)?
              sum + assets.quantity_of(output.value, policy_id, asset_name)
            } else {
              sum
            }
          },
        )
      |> builtin.equals_data(1)

  let must_not_mint_anything_else =
    // While this may seem redundant with the check above, this ensures that
    // nothing ELSE is minted with the token.
    self.mint
      |> assets.tokens(policy_id)
      |> dict.to_pairs
      |> builtin.equals_data([Pair(asset_name, 1)])

  and {
    must_spend_seed_utxo?,
    must_trap_token?,
    must_not_mint_anything_else?,
  }
}

fn burn_one(policy_id: PolicyId, asset_name: AssetName, self: Transaction) {
  let must_burn_token =
    self.mint
      |> assets.tokens(policy_id)
      |> dict.to_pairs
      |> builtin.equals_data([Pair(asset_name, -1)])

  and {
    must_be_approved_by_general_assembly(self)?,
    must_burn_token?,
  }
}
