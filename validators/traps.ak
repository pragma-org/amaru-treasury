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
use inputs
use outputs
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
    let asset_name = config.scopes_token_name
    let with_state =
      with_inline_scopes(_, fn(_) { True })
    spend(asset_name, with_state, utxo, self)
  }

  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    let asset_name = config.scopes_token_name
    let with_state =
      with_inline_scopes(_, fn(_) { True })
    mint_or_burn(seed, asset_name, with_state, policy_id, self)
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
    let asset_name = scope.to_bytearray(scope)
    let with_state =
      with_inline_registry(_, fn(_) { True })
    spend(asset_name, with_state, utxo, self)
  }

  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    let asset_name = scope.to_bytearray(scope)
    let with_state =
      with_inline_registry(_, fn(_) { True })
    mint_or_burn(seed, asset_name, with_state, policy_id, self)
  }

  // Allow other types of operations (e.g. stake delegation) at the
  // discretion of the general assembly. This should be mostly useless in
  // practice but prevent from being stuck in undesirable situations.
  else(ctx: ScriptContext) {
    must_be_approved_by_general_assembly(ctx.transaction)?
  }
}

/// Ensures a transaction is properly authenticated by the admin credentials (i.e. the GA).
fn must_be_approved_by_general_assembly(tx: Transaction) -> Bool {
  multisig.satisfied(
    admin,
    tx.extra_signatories,
    tx.validity_range,
    tx.withdrawals,
  )
}

/// A spending policy for trapped tokens, parameterized by an asset name and
/// a function to assert the shape of the output's datum.
fn spend(
  asset_name: AssetName,
  with_state: fn(Datum) -> Bool,
  utxo: OutputReference,
  self: Transaction,
) -> Bool {
  expect must_be_approved_by_general_assembly(self)

  expect Credential.Script(own_script) =
    inputs.resolve(self.inputs, utxo).address.payment_credential

  or {
    // either the token is burnt;
    (assets.tokens(self.mint, own_script) != dict.empty)?,
    // or the output is forwarded.
    {
      let output = outputs.forwarding_nft(own_script, asset_name, self.outputs)
      with_state(output.datum)?
    },
  }
}

/// A minting or burning policy. It ensures that minting can only happen once
/// (piggybacking on UTxO's spending uniqueness) and for a quantity of exactly
/// one token.
fn mint_or_burn(
  seed: OutputReference,
  asset_name: AssetName,
  with_state: fn(Datum) -> Bool,
  policy_id: PolicyId,
  self: Transaction,
) -> Bool {
  or {
    mint(seed, policy_id, asset_name, with_state, self)?,
    burn(policy_id, asset_name, self)?,
  }
}

fn mint(
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

fn burn(policy_id: PolicyId, asset_name: AssetName, self: Transaction) {
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
