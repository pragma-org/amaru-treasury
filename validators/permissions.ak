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

use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential}
use cardano/assets
use cardano/script_context.{ScriptContext}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use config
use inputs.{expect_single_script}
use outputs.{total_at}
use scope.{
  Scope, approved_by_owner, approved_by_owner_and_someone_else, expect_scopes,
}
use sundae.{OrderDatum, expect_order_datum}
use value.{from_ada}

const order_contract = Credential.Script(config.sundae_order_contract)

pub type Authorization {
  /// Rely on the standard approval mecanism for the action (i.e.
  /// authorization from the scope owner + another scope owner).
  Standard

  /// We allow an exception for swapping ADA -> USDM. This operation can be
  /// perform solely by the scope owner but comes with additional restriction
  /// regarding where the funds can be sent and for what price.
  ///
  /// The reverse operation is more delicate, because of ADA price movements.
  /// Plus, it would require adopting a more active treasury management strategy
  /// which also comes with many ramifications from an auditability and tax
  /// perspectives.
  ///
  /// So we don't make room for it. Yet, it is still doable via a 'Standard'
  /// authorization (with 2 overseeing signers).
  SwapOrder { ada: Int, usdm: Int }

  /// Cancel a previously emitted swap order, back to the treasury. We not allow
  /// chaining swaps (i.e. cancelling one into a new one). While this could be
  /// possible, it would add complexity to the validator, which is already fairly
  /// complex.
  ///
  /// So instead, we force cancellation to return funds to the treasury; and a new
  /// 'Disburse' action can take place for publishing a new order.
  SwapCancel
}

/// A generic scope owner validator which is used as a companion script for the
/// treasury management contract.
///
/// It defines the ownership rules in addition to the logic corresponding to the
/// sweep, reorganize, disburse and fund actions.
///
validator permissions(scopes_ref: ScriptHash, scope: Scope) {
  // The 'withdraw' purpose is used by sundae/multisig to simulate a
  // remote-call from another script. So this is effectively the script
  // interface to others.
  withdraw(redeemer: Authorization, credential: Credential, self: Transaction) {
    expect Credential.Script(owner) = credential

    when redeemer is {
      // The standard strategy is rather simple: we check that the scope owner and at least
      // one other scope owner approved. The main challenge stems from how the scope
      // owners are defined dynamically, as a UTxO's state owned by another contract.
      Standard ->
        approved_by_owner_and_someone_else(
          self,
          scope,
          expect_scopes(self.reference_inputs, scopes_ref),
        )

      // A swap is more involved, as we must ensure that we can only swap some
      // specific assets, at a minimum price rate. The swap can also
      // unfortunately not happen in a single transaction, so we must
      // effectively hand-over funds to a smart contract, and ensure that they
      // can only ever go back to the treasury (either from a swap, or from a
      // cancellation)
      SwapOrder { ada, usdm } -> {
        // Must be approved by the scope owner no matter what.
        expect
          approved_by_owner(
            self,
            scope,
            expect_scopes(self.reference_inputs, scopes_ref),
          )

        // We do not know what the treasury script is, and we cannot easily
        // because it creates a circular dependency between this script and the
        // treasury. So we really have two options:
        //
        // 1. We could use the *registry utxo* that the treasury contract also
        //    uses, and which should refer to the treasury validator indirectly
        //    (stored in a datum). The requires parameterizing this script by
        //    yet-another-dynamic-parameter.
        //
        // 2. We can assume that whatever input script we're trying to spend
        //    from is, by definition, the treasury. This is only sound if we only spend from
        //    one distinct script (possibly spread over multiple UTxOs).
        //
        // We go for (2) here; which, in fact, ensures that this authentication
        // side-car script remains decoupled from the treasury. In fact, as far
        // as we're concerned, this script can work with any treasury. And we could imagine
        // re-using it in other context.
        //
        // After all, the inputs being spent here are the one providing the liquidity, so it's only
        // fair that they also become the swap destination.
        let treasury_script, treasury <- expect_single_script(self.inputs)
        let treasury_address = address.from_script(treasury_script)

        // This prevent a scenario where one would attempt to cancel a swap order using
        // a 'SwapOrder' redeemer. This invalidate our key assumption that the script-locked
        // funds being spent belongs to the treasury.
        //
        // We cover the swap cancellation as a separate redeemer case, and one is expected to
        // use the `SwapCancel` action for it.
        expect treasury_address.payment_credential != order_contract

        // We always expect the swap output to be second, while the treasury
        // output remains first. This requirement only speeds up execution (as
        // we need not to search for outputs) without being too annoying from a
        // UX standpoint.
        //
        // Remaining outputs are left unconstrained.
        expect [treasury_output, swap_output, ..] = self.outputs

        // Ensures that we send the treasury to the right address. Note that there's no constraint
        // about what the datum can be at that address (or whether there's even one).
        expect treasury_output.address == treasury_address

        // Ensures that we send the order to the right address, and that they remain
        // delegated to whatever the treasury is delegated to. This is crucial to ensure
        // that while there's a standing order, we still comply with the constitution.
        expect
          swap_output.address == sundae.order_address(
            treasury_address.stake_credential,
          )

        // We should lock exactly the expected amount of Ada, which corresponds to:
        // The amount being swapped plus the protocol fees.
        let ada_plus_fee = ada + config.sundae_protocol_fee
        let total_value_locked = from_ada(ada_plus_fee)
        expect swap_output.value == total_value_locked

        // The treasury should deplete by as much. Any concern related to
        // min ada value must be taken care of by whomever constructs the
        // transaction.
        let leftovers = assets.merge(treasury, from_ada(-ada_plus_fee))
        expect treasury_output.value == leftovers

        // At last, check the order datum.
        swap_output.datum == InlineDatum(
          sundae.ada_to_usdm(owner, treasury_address, ada, usdm),
        )
      }

      SwapCancel -> {
        // Must be approved by the scope owner no matter what.
        expect
          approved_by_owner(
            self,
            scope,
            expect_scopes(self.reference_inputs, scopes_ref),
          )

        // We only allow to cancel one swap order at a time.
        expect [Input { output: order, .. }] =
          inputs.locked_by(self.inputs, order_contract)

        let OrderDatum { destination, .. } = expect_order_datum(order.datum)

        // Everything in the order can go back to the "treasury" which in this case
        // must be our destination address. This supposes that the destination
        // was rightfully constructed to begin with, which 'SwapOrder' enforces.
        //
        // Note that this script could also technically be used to cancel any
        // order on Sundae that defines it as the owner. In which case, the
        // destination is whatever the order author chose it to be. While
        // arguably pointless, it is seemingly harmless.
        let back_to_treasury =
          total_at(self.outputs, assets.zero, destination.address)

        order.value == back_to_treasury
      }
    }
  }

  // For anything else, we let the scope owner manage the
  // script however they like. Note that this script isnt
  // supposed to hold any funds; it is merely published and
  // used 'as a remote module' by the main treasury script.
  else(ctx: ScriptContext) {
    let ScriptContext { transaction, .. } = ctx
    approved_by_owner(
      transaction,
      scope,
      expect_scopes(transaction.reference_inputs, scopes_ref),
    )
  }
}
