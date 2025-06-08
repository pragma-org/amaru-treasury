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

use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{RegisterCredential}
use cardano/script_context.{ScriptContext, ScriptInfo}
use cardano/transaction.{Transaction}
use inputs.{expect_single_script}
use scope.{
  Scope, approved_by_owner, approved_by_owner_and_someone_else, expect_scopes,
}
use types.{Disburse, Fund, Reorganize, SweepTreasury, TreasurySpendRedeemer}

/// A generic scope owner validator which is used as a companion script for the
/// treasury management contract.
///
/// It defines the ownership rules in addition to the logic corresponding to the
/// sweep, reorganize, disburse and fund actions.
///
validator permissions(scopes_nft: PolicyId, scope: Scope) {
  // The 'withdraw' purpose is used by sundae/multisig to simulate a
  // remote-call from another script. So this is effectively the script
  // interface to others.
  //
  // The strategy is rather simple and depends on the treasury action
  // that's being required.
  //
  // - for sweep & disburse: requires the scope owner and another scope owner.
  // - for reorganize: requires only the scope owner.
  // - for fund: not authorized whatsoever.
  //
  // Credentials for scope owners are defined dynamically, as a UTxO's
  // state owned by another validator.
  withdraw(_redeemer: Data, _credential: Credential, self: Transaction) {
    let
      _treasury_script,
      redeemer,
    <- expect_single_script(self.inputs, self.redeemers)

    expect redeemer: TreasurySpendRedeemer = redeemer

    when redeemer is {
      Reorganize ->
        approved_by_owner(
          self,
          scope,
          expect_scopes(self.reference_inputs, scopes_nft),
        )

      SweepTreasury | Disburse { .. } ->
        approved_by_owner_and_someone_else(
          self,
          scope,
          expect_scopes(self.reference_inputs, scopes_nft),
        )

      Fund { .. } -> False
    }
  }

  // For anything else, we let the scope owner manage the
  // script however they like. Note that this script isnt
  // supposed to hold any funds; it is merely published and
  // used 'as a remote module' by the main treasury script.
  else(ctx: ScriptContext) {
    let ScriptContext { transaction, .. } = ctx
    or {
      when ctx.info is {
        ScriptInfo.Publishing {
          // To ease UX for setting up the contract, allows registering stake credential without any signer.
          certificate: RegisterCredential { .. },
          ..
        } -> True
        _ -> False
      },
      approved_by_owner(
        transaction,
        scope,
        expect_scopes(transaction.reference_inputs, scopes_nft),
      ),
    }
  }
}
