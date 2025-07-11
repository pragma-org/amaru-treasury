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
use aiken/interval.{is_entirely_after}
use cardano/address.{Credential, Script}
use cardano/assets.{AssetName, PolicyId}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{Datum, Input, Output, OutputReference, Transaction}
use config
use inputs
use outputs
use scope.{Scope, Scopes, expect_inline_scopes}
use sundae/multisig
use types.{ScriptHashRegistry as Registry, ScriptHashRegistry}

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
      fn(_, new_datum) {
        // Allow updates, but enforces that the new datum is at least:
        //
        // (a) present;
        // (b) of the right shape.
        expect_inline_scopes(new_datum)
      }

    spend(asset_name, with_state, utxo, self)
  }

  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    let asset_name = config.scopes_token_name
    or {
      burn(policy_id, asset_name, self)?,
      mint(seed, policy_id, asset_name, expect_inline_scopes, self)?,
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
///
/// Unlike the 'scopes' validator, modification of the registry aren't allowed.
validator treasury_registry(seed: OutputReference, scope: Scope) {
  spend(
    _datum: Option<Data<Registry>>,
    _redeemer: Data,
    utxo: OutputReference,
    self: Transaction,
  ) {
    let asset_name = types.registry_token_name()

    let with_state =
      fn(old_datum: Option<Datum>, new_datum: Datum) {
        or {
          // Note that we need not to re-assert the shape of the new datum
          // here, because it is checked during minting, and we do not allow
          // the slightest change anyway.
          (old_datum == Some(new_datum))?,
          // Allow spending from marginal UTxOs.
          (old_datum == None)?,
        }
      }

    spend(asset_name, with_state, utxo, self)
  }

  mint(_redeemer: Data, policy_id: PolicyId, self: Transaction) {
    trace @"scope": scope
    let asset_name = types.registry_token_name()

    // Assert (or fail) that a given datum is inline and has an expected shape.
    let expect_script_registry =
      fn(datum: Datum) {
        expect Datum.InlineDatum(data) = datum
        expect _: ScriptHashRegistry = data
        True
      }

    or {
      burn(policy_id, asset_name, self)?,
      mint(seed, policy_id, asset_name, expect_script_registry, self)?,
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
  with_state: fn(Option<Datum>, Datum) -> Bool,
  utxo: OutputReference,
  self: Transaction,
) -> Bool {
  expect must_be_approved_by_general_assembly(self)

  let own_input = inputs.resolve(self.inputs, utxo)

  expect Credential.Script(own_script) = own_input.address.payment_credential

  or {
    // either the token is burnt;
    (assets.tokens(self.mint, own_script) != dict.empty)?,
    // or the output is forwarded.
    {
      let output = outputs.forwarding_nft(own_script, asset_name, self.outputs)

      expect output.reference_script == None

      // Retrieve the managed datum, if any. We only trust the datum that is trapped with
      // the NFT.
      let own_datum =
        if assets.quantity_of(own_input.value, own_script, asset_name) == 1 {
          Some(own_input.datum)
        } else {
          None
        }

      with_state(own_datum, output.datum)?
    },
  }
}

fn mint(
  seed: OutputReference,
  policy_id: PolicyId,
  asset_name: AssetName,
  expect_datum: fn(Datum) -> Bool,
  self: Transaction,
) {
  // Just a sanity check to ensure that the expiration date is in the future,
  // prior to bootstrapping the validator. It's pretty easy to shoot oneself in
  // the foot between seconds / milliseconds.
  //
  // So this deserves a small check during the mint procedure.
  expect config.expiration > 1749400000000

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
              expect output.reference_script == None
              expect outputs.expect_nft(output.value, policy_id, asset_name)
              sum + 1
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

  let must_have_expired =
    self.validity_range
      |> is_entirely_after(config.expiration)

  and {
    must_be_approved_by_general_assembly(self)?,
    must_have_expired?,
    must_burn_token?,
  }
}
