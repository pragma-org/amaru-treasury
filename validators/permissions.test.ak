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

use aiken/collection/dict
use aiken/collection/list.{for_each}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use aiken/fuzz.{and_then, constant as return}
use aiken/fuzz/scenario.{Label, Scenario}
use cardano/address.{Credential}
use cardano/assets.{Lovelace, PolicyId}
use cardano/fuzz as cardano
use cardano/transaction.{InlineDatum, Input, Output, ScriptPurpose, Transaction}
use config
use permissions as handlers
use scope.{Scope, Scopes}
use sundae/multisig
use types.{TreasurySpendRedeemer}

// ----------------------------------------------------------------------------
// ----- Config
// ----------------------------------------------------------------------------

const validator_hash: ScriptHash =
  #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

const scopes_nft: PolicyId =
  #"99999999999999999999999999999999999999999999999999999999"

const ledger: VerificationKeyHash = #"1ed6ee"

const consensus: VerificationKeyHash = #"c0d5ed50"

const mercenaries: VerificationKeyHash = #"4eecedad15"

const marketing: VerificationKeyHash = #"4ad3e716"

const all_owners: List<VerificationKeyHash> =
  [ledger, consensus, mercenaries, marketing]

// ----------------------------------------------------------------------------
// ----- Properties
// ----------------------------------------------------------------------------

fn run_as(scope: Scope, txs: List<Transaction>) {
  let default_handler =
    handlers.permissions.else(scopes_nft, scope, _)

  scenario.run(
    txs,
    validator_hash,
    scenario.into_mint_handler(default_handler),
    scenario.into_spend_handler(default_handler),
    handlers.permissions.withdraw(scopes_nft, scope, _, _, _),
    scenario.into_publish_handler(default_handler),
    scenario.into_vote_handler(default_handler),
  )
}

// Assess the frequency of O.K. vs K.O. scenarii, ensuring that we maintain a
// reasonable distribution as we complexify scenarii down the line.
test prop_permissions_scenarii_distribution(
  outcome via scenario.report_coverage(
    // We reasonably expect the same coverage for all scopes.
    default_state(Scope.Ledger),
    step,
  ),
) {
  fuzz.label_when(outcome == scenario.Ok, @"O.K.", @"K.O.")
}

test permissions_ko_coverage() {
  scenario.check_coverage(
    all_failures,
    scenario.ko(default_state(Scope.Ledger), step),
  )
}

// -------------------------------------------------------------------
// ----- Properties :: Ledger
// -------------------------------------------------------------------

test prop_permissions_ledger_standard_ok(
  ok via scenario.ok(default_state(Scope.Ledger), step),
) {
  run_as(Scope.Ledger, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_ledger_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Ledger), step),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Ledger, ko)
}

// -------------------------------------------------------------------
// ----- Properties :: Consensus
// -------------------------------------------------------------------

test prop_permissions_consensus_standard_ok(
  ok via scenario.ok(default_state(Scope.Consensus), step),
) {
  run_as(Scope.Consensus, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_consensus_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Consensus), step),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Consensus, ko)
}

// -------------------------------------------------------------------
// ----- Properties :: Mercenaries
// -------------------------------------------------------------------

test prop_permissions_mercenaries_standard_ok(
  ok via scenario.ok(default_state(Scope.Mercenaries), step),
) {
  run_as(Scope.Mercenaries, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_mercenaries_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Mercenaries), step),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Mercenaries, ko)
}

// -------------------------------------------------------------------
// ----- Properties :: Marketing
// -------------------------------------------------------------------

test prop_permissions_marketing_standard_ok(
  ok via scenario.ok(default_state(Scope.Marketing), step),
) {
  run_as(Scope.Marketing, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_marketing_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Marketing), step),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Marketing, ko)
}

// -------------------------------------------------------------------
// ----- Properties :: Contingency
// -------------------------------------------------------------------

test prop_permissions_contingency_standard_ok(
  ok via scenario.ok(default_state(Scope.Contingency), step),
) {
  run_as(Scope.Contingency, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_contingency_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Contingency), step),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Contingency, ko)
}

// ----------------------------------------------------------------------------
// ----- Failing scenarii
// ----------------------------------------------------------------------------

const no_script_inputs: String = @"· no script inputs"

const mixed_scripts_inputs: String = @"· mixed scripts inputs"

const mixed_spend_redeemers: String = @"· mixed spend redeemers"

const missing_scope_owner: String = @"· missing scope owner signature"

const insufficient_signatories: String = @"· missing signatories (others)"

const missing_scopes: String = @"· missing scopes input reference"

const malformed_scopes: String = @"· malformed scopes datum"

const all_failures: List<String> =
  [
    no_script_inputs, mixed_scripts_inputs, mixed_spend_redeemers,
    missing_scope_owner, insufficient_signatories, missing_scopes,
    malformed_scopes,
  ]

// ----------------------------------------------------------------------------
// ----- Post-conditions
// ----------------------------------------------------------------------------

fn post_conditions(scenario: Transaction) {
  let count_script_locked =
    list.count(
      scenario.inputs,
      fn(input) {
        when input.output.address.payment_credential is {
          Credential.Script(..) -> True
          _ -> False
        }
      },
    )

  let signatories = list.unique(scenario.extra_signatories)

  expect Some(Pair(_, data)) =
    list.find(
      scenario.redeemers,
      fn(Pair(key, _)) {
        when key is {
          ScriptPurpose.Spend(..) -> True
          _ -> False
        }
      },
    )

  expect redeemer: TreasurySpendRedeemer = data

  let (is_disburse, is_reorganize, is_sweep) =
    when redeemer is {
      TreasurySpendRedeemer.Disburse { .. } -> (True, False, False)
      TreasurySpendRedeemer.Reorganize -> (False, True, False)
      TreasurySpendRedeemer.SweepTreasury -> (False, False, True)
      TreasurySpendRedeemer.Fund { .. } -> (False, False, False)
    }

  []
    |> scenario.classify(
        @"· more than one script-locked input",
        count_script_locked > 1,
      )
    |> scenario.classify(
        @"· more signers than necessary",
        list.length(signatories) > 2,
      )
    |> scenario.classify(
        @"· more than one reference inputs",
        list.length(scenario.reference_inputs) > 1,
      )
    |> scenario.classify(@"· action = disburse", is_disburse)
    |> scenario.classify(@"· action = reorganize", is_reorganize)
    |> scenario.classify(@"· action = sweep", is_sweep)
    |> for_each(fuzz.label)
}

// ----------------------------------------------------------------------------
// ----- State
// ----------------------------------------------------------------------------

type State {
  labels: List<Label>,
  scope: Scope,
  done: Bool,
}

fn default_state(scope: Scope) -> State {
  State { labels: [], scope, done: False }
}

type Weights {
  scenario_inputs: Int,
  scenario_reference_inputs: Int,
  scenario_scopes_datum: Int,
  scenario_redeemers: Int,
  scenario_signatories: Int,
}

const weights =
  Weights {
    scenario_inputs: 220,
    scenario_reference_inputs: 210,
    scenario_scopes_datum: 210,
    scenario_redeemers: 210,
    scenario_signatories: 180,
  }

// ----------------------------------------------------------------------------
// ----- Step
// ----------------------------------------------------------------------------

fn step(st: State) -> Fuzzer<Scenario<State>> {
  if st.done {
    return(Scenario.Done)
  } else {
    let action <- and_then(spend_redeemer())

    let (st, inputs) <-
      scenario.fork2_and_then(
        weights.scenario_inputs,
        fn() { scenario_inputs_baseline(st) },
        fn() { scenario_inputs_no_scripts(st) },
        fn() { scenario_inputs_mixed_scripts(st) },
      )

    let (st, reference_inputs) <-
      scenario.fork_and_then(
        weights.scenario_reference_inputs,
        fn() { scenario_ref_inputs_baseline(st) },
        fn() { scenario_ref_inputs_missing_scopes(st) },
      )

    let withdrawals <- and_then(scenario_withdrawals_baseline())

    let (st, redeemers) <-
      scenario.fork_if_and_then(
        st.labels == [],
        weights.scenario_redeemers,
        fn() { scenario_redeemers_baseline(st, inputs, action) },
        fn() { scenario_redeemers_mixed(st, inputs, action) },
      )

    let (st, extra_signatories) <-
      scenario.fork2_and_then(
        weights.scenario_signatories,
        fn() { scenario_signatories_baseline(st, action) },
        fn() { scenario_signatories_missing_owner(st, action) },
        fn() { scenario_signatories_missing_other(st, action) },
      )

    return(
      Scenario.Step(
        st.labels,
        State { ..st, done: True, labels: [] },
        Transaction {
          ..transaction.placeholder,
          inputs: inputs,
          reference_inputs: reference_inputs,
          withdrawals: withdrawals,
          extra_signatories: extra_signatories,
          redeemers: redeemers,
        },
      ),
    )
  }
}

// ----------------------------------------------------------------------------
// ----- Generators
// ----------------------------------------------------------------------------

// ------------------------------------------------------------------
// ----- Generators :: Inputs
// ------------------------------------------------------------------

fn scenario_inputs_baseline(st: State) -> Fuzzer<(State, List<Input>)> {
  let treasury_hash <- and_then(cardano.script_hash())

  let inputs <-
    and_then(
      fuzz.such_that(
        fuzz.list_at_least(
          fuzz.either(
            input_with_payment_credential(cardano.verification_key()),
            input_with_payment_credential(
              return(Credential.Script(treasury_hash)),
            ),
          ),
          1,
        ),
        // At least one input has a script.
        fn(inputs) {
          let input <- list.any(inputs)
          when input.output.address.payment_credential is {
            Credential.Script(..) -> True
            _ -> False
          }
        },
      ),
    )

  return((st, inputs))
}

fn scenario_inputs_mixed_scripts(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs <-
    and_then(
      fuzz.such_that(
        fuzz.list_at_least(cardano.input(), 2),
        // At least one input has a script.
        fn(inputs) {
          let n =
            list.foldl(
              inputs,
              dict.empty,
              fn(input, set) {
                when input.output.address.payment_credential is {
                  Credential.Script(hash) -> dict.insert(set, hash, Void)
                  _ -> set
                }
              },
            )
              |> dict.size
          n >= 2
        },
      ),
    )

  return((State { ..st, labels: [mixed_scripts_inputs, ..st.labels] }, inputs))
}

fn scenario_inputs_no_scripts(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs <-
    and_then(
      fuzz.list_at_least(
        input_with_payment_credential(cardano.verification_key()),
        1,
      ),
    )

  return((State { ..st, labels: [no_script_inputs, ..st.labels] }, inputs))
}

// ------------------------------------------------------------------
// ----- Generators :: Reference Inputs
// ------------------------------------------------------------------

fn scenario_ref_inputs_baseline(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs_before <- and_then(fuzz.list_between(cardano.input(), 0, 1))

  let input <- and_then(cardano.input())

  let (st, datum) <-
    scenario.fork_and_then(
      weights.scenario_scopes_datum,
      fn() { scenario_scopes_datum_baseline(st) },
      fn() { scenario_scopes_datum_malformed(st) },
    )

  let input =
    Input {
      ..input,
      output: Output {
        ..input.output,
        datum: InlineDatum(datum),
        value: assets.add(
          input.output.value,
          scopes_nft,
          config.scopes_token_name,
          1,
        ),
      },
    }

  let inputs_after <- and_then(fuzz.list_between(cardano.input(), 0, 1))

  let inputs = list.concat(inputs_before, [input, ..inputs_after])

  return((st, inputs))
}

fn scenario_scopes_datum_baseline(st: State) -> Fuzzer<(State, Data)> {
  return(
    (
      st,
      as_data(
        Scopes {
          ledger: multisig.Signature(ledger),
          consensus: multisig.Signature(consensus),
          mercenaries: multisig.Signature(mercenaries),
          marketing: multisig.Signature(marketing),
        },
      ),
    ),
  )
}

fn scenario_scopes_datum_malformed(st: State) -> Fuzzer<(State, Data)> {
  let data <-
    fuzz.map(
      fuzz.such_that(
        fuzz.data(),
        fn(data) {
          if data is _: Scopes {
            False
          } else {
            True
          }
        },
      ),
    )

  (State { ..st, labels: [malformed_scopes, ..st.labels] }, data)
}

fn scenario_ref_inputs_missing_scopes(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs <- and_then(fuzz.list(cardano.input()))
  return((State { ..st, labels: [missing_scopes, ..st.labels] }, inputs))
}

// ------------------------------------------------------------------
// ----- Generators :: Withdrawals
// ------------------------------------------------------------------

fn scenario_withdrawals_baseline() -> Fuzzer<Pairs<Credential, Lovelace>> {
  let amount <- fuzz.map(fuzz.int_at_least(0))

  let withdrawals =
    [
      // Always include a withdrawal for our validator, otherwise nothing
      // is being tested...
      Pair(Credential.Script(validator_hash), amount),
    ]

  withdrawals
}

// ------------------------------------------------------------------
// ----- Generators :: Redeemers
// ------------------------------------------------------------------

fn scenario_redeemers_baseline(
  st: State,
  inputs: List<Input>,
  action: TreasurySpendRedeemer,
) -> Fuzzer<(State, Pairs<ScriptPurpose, Data>)> {
  let redeemers =
    inputs
      |> list.foldl(
          [],
          fn(input, redeemers) {
            when input.output.address.payment_credential is {
              Credential.Script(..) ->
                [
                  Pair(
                    ScriptPurpose.Spend(input.output_reference),
                    as_data(action),
                  ),
                  ..redeemers
                ]
              Credential.VerificationKey(..) -> redeemers
            }
          },
        )

  return((st, [withdraw, ..redeemers]))
}

fn scenario_redeemers_mixed(
  st: State,
  inputs: List<Input>,
  action: TreasurySpendRedeemer,
) -> Fuzzer<(State, Pairs<ScriptPurpose, Data>)> {
  let other_action <-
    and_then(
      fuzz.such_that(
        spend_redeemer(),
        fn(other_action) { other_action != action },
      ),
    )

  let Pair(count, redeemers) =
    inputs
      |> list.foldl(
          Pair(0, []),
          fn(input, Pair(count, redeemers)) {
            when input.output.address.payment_credential is {
              Credential.Script(..) ->
                Pair(
                  count + 1,
                  [
                    Pair(
                      ScriptPurpose.Spend(input.output_reference),
                      if count == 0 {
                        as_data(action)
                      } else {
                        as_data(other_action)
                      },
                    ),
                    ..redeemers
                  ],
                )
              Credential.VerificationKey(..) -> Pair(count, redeemers)
            }
          },
        )

  return(
    (
      if count > 1 {
        State { ..st, labels: [mixed_spend_redeemers, ..st.labels] }
      } else {
        st
      },
      [withdraw, ..redeemers],
    ),
  )
}

// ------------------------------------------------------------------
// ----- Generators :: Signatories
// ------------------------------------------------------------------

fn scenario_signatories_baseline(
  st: State,
  action: TreasurySpendRedeemer,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let signatories <-
    fuzz.map(
      when action is {
        TreasurySpendRedeemer.Disburse { .. } |
        TreasurySpendRedeemer.SweepTreasury ->
          when st.scope is {
            Scope.Ledger -> {
              let others <-
                and_then(non_empty_sublist([consensus, mercenaries, marketing]))
              return([ledger, ..others])
            }
            Scope.Consensus -> {
              let others <-
                and_then(non_empty_sublist([ledger, mercenaries, marketing]))
              return([consensus, ..others])
            }
            Scope.Mercenaries -> {
              let others <-
                and_then(non_empty_sublist([ledger, consensus, marketing]))
              return([mercenaries, ..others])
            }
            Scope.Marketing -> {
              let others <-
                and_then(non_empty_sublist([ledger, consensus, mercenaries]))
              return([marketing, ..others])
            }
            Scope.Contingency -> return(all_owners)
          }

        TreasurySpendRedeemer.Reorganize ->
          when st.scope is {
            Scope.Ledger -> return([ledger])
            Scope.Consensus -> return([consensus])
            Scope.Mercenaries -> return([mercenaries])
            Scope.Marketing -> return([marketing])
            Scope.Contingency -> non_empty_sublist(all_owners)
          }

        TreasurySpendRedeemer.Fund { .. } -> {
          trace @"unsupported action": action
          fail
        }
      },
    )

  (st, signatories)
}

fn scenario_signatories_missing_other(
  st: State,
  action: TreasurySpendRedeemer,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let tail <- fuzz.and_then(fuzz.list(cardano.verification_key_hash()))

  let signatories <-
    fuzz.map(
      when st.scope is {
        Scope.Ledger -> return([ledger, ..tail])
        Scope.Consensus -> return([consensus, ..tail])
        Scope.Mercenaries -> return([mercenaries, ..tail])
        Scope.Marketing -> return([marketing, ..tail])
        Scope.Contingency -> {
          let owners <-
            fuzz.map(
              fuzz.such_that(
                fuzz.sublist(all_owners),
                fn(sub) { sub != all_owners },
              ),
            )
          list.concat(owners, tail)
        }
      },
    )

  when action is {
    TreasurySpendRedeemer.Disburse { .. } | TreasurySpendRedeemer.SweepTreasury ->
      (
        State { ..st, labels: [insufficient_signatories, ..st.labels] },
        signatories,
      )
    TreasurySpendRedeemer.Reorganize ->
      // Any owner can re-organize, but for the Contingency scope, we at least need
      // one of them.
      if st.scope == Scope.Contingency && signatories == tail {
        (
          State { ..st, labels: [insufficient_signatories, ..st.labels] },
          signatories,
        )
      } else {
        (st, signatories)
      }
    TreasurySpendRedeemer.Fund { .. } -> {
      trace @"unsupported action": action
      fail
    }
  }
}

fn scenario_signatories_missing_owner(
  st: State,
  action: TreasurySpendRedeemer,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let signatories <-
    fuzz.map(
      when st.scope is {
        Scope.Ledger -> fuzz.sublist([consensus, mercenaries, marketing])
        Scope.Consensus -> fuzz.sublist([ledger, mercenaries, marketing])
        Scope.Mercenaries -> fuzz.sublist([ledger, consensus, marketing])
        Scope.Marketing -> fuzz.sublist([ledger, consensus, mercenaries])
        Scope.Contingency ->
          when action is {
            TreasurySpendRedeemer.Disburse { .. } |
            TreasurySpendRedeemer.SweepTreasury ->
              fuzz.such_that(
                fuzz.sublist(all_owners),
                fn(sub) { sub != all_owners },
              )
            TreasurySpendRedeemer.Reorganize -> return([])
            TreasurySpendRedeemer.Fund { .. } -> {
              trace @"unsupported action": action
              fail
            }
          }
      },
    )

  (State { ..st, labels: [missing_scope_owner, ..st.labels] }, signatories)
}

// ----------------------------------------------------------------------------
// ----- Helpers
// ----------------------------------------------------------------------------

const withdraw: Pair<ScriptPurpose, Data> =
  Pair(ScriptPurpose.Withdraw(Credential.Script(validator_hash)), as_data(Void))

fn spend_redeemer() -> Fuzzer<TreasurySpendRedeemer> {
  fuzz.one_of(
    [
      TreasurySpendRedeemer.SweepTreasury,
      TreasurySpendRedeemer.Reorganize,
      TreasurySpendRedeemer.Disburse([]),
    ],
  )
}

fn non_empty_sublist(elems: List<a>) -> Fuzzer<List<a>> {
  fuzz.such_that(fuzz.sublist(elems), fn(xs) { xs != [] })
}

fn input_with_payment_credential(
  payment_credential: Fuzzer<Credential>,
) -> Fuzzer<Input> {
  cardano.input_with(
    cardano.output_reference(),
    cardano.output_with(
      cardano.address_with(
        payment_credential,
        fuzz.option(cardano.stake_credential()),
      ),
      cardano.value(assets.zero),
      cardano.datum(),
      cardano.reference_script(),
    ),
  )
}
