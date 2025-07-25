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
////

use aiken/collection/dict
use aiken/collection/list.{for_each}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use aiken/fuzz.{and_then, constant as return}
use aiken/fuzz/scenario.{Label, Scenario}
use aiken/interval.{Interval}
use cardano/address.{Address, Credential}
use cardano/assets.{AssetName, Value}
use cardano/fuzz as cardano
use cardano/transaction.{
  Datum, InlineDatum, Input, Output, OutputReference, ScriptPurpose, Transaction,
}
use config
use scope.{Scope, Scopes}
use sundae/multisig.{MultisigScript}
use traps as handlers
use types.{ScriptHashRegistry as Registry}

// ----------------------------------------------------------------------------
// ----- Config
// ----------------------------------------------------------------------------

const validator_hash: ScriptHash =
  #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

const seed: OutputReference =
  OutputReference { transaction_id: "seed", output_index: 99 }

// ----------------------------------------------------------------------------
// ----- Properties :: scopes
// ----------------------------------------------------------------------------

const default_scopes_handler = handlers.scopes.else(seed, _)

test prop_scopes_ok(
  ok via scenario.ok(default_state(config.scopes_token_name, KindScopes), step),
) {
  run_scopes(ok)
  post_conditions(ok)
}

test prop_scopes_ko(
  (labels, ko) via scenario.ko(
    default_state(config.scopes_token_name, KindScopes),
    step,
  ),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_scopes(ko)
}

// Assess the frequency of O.K. vs K.O. scenarii, ensuring that we maintain a
// reasonable distribution as we complexify scenarii down the line.
test prop_scopes_scenarii_distribution(
  outcome via scenario.report_coverage(
    default_state(config.scopes_token_name, KindScopes),
    step,
  ),
) {
  fuzz.label_when(outcome == scenario.Ok, @"O.K.", @"K.O.")
}

// Ensures we eventually cover all K.O. scenarii.
test scopes_ko_coverage() {
  scenario.check_coverage(
    all_scopes_failures,
    scenario.ko(default_state(config.scopes_token_name, KindScopes), step),
  )
}

fn run_scopes(txs: List<Transaction>) {
  scenario.run(
    txs,
    validator_hash,
    handlers.scopes.mint(seed, _, _, _),
    handlers.scopes.spend(seed, _, _, _, _),
    scenario.into_withdraw_handler(default_scopes_handler),
    scenario.into_publish_handler(default_scopes_handler),
    scenario.into_vote_handler(default_scopes_handler),
  )
}

// ----------------------------------------------------------------------------
// ----- Properties :: registry
// ----------------------------------------------------------------------------

const default_scope: Scope = Scope.Ledger

const default_registry_handler =
  handlers.treasury_registry.else(seed, default_scope, _)

test prop_registry_ok(
  ok via scenario.ok(
    default_state(types.registry_token_name(), KindRegistry),
    step,
  ),
) {
  run_registry(ok)
  post_conditions(ok)
}

test prop_registry_ko(
  (labels, ko) via scenario.ko(
    default_state(types.registry_token_name(), KindRegistry),
    step,
  ),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_registry(ko)
}

// Assess the frequency of O.K. vs K.O. scenarii, ensuring that we maintain a
// reasonable distribution as we complexify scenarii down the line.
test prop_registry_scenarii_distribution(
  outcome via scenario.report_coverage(
    default_state(types.registry_token_name(), KindRegistry),
    step,
  ),
) {
  fuzz.label_when(outcome == scenario.Ok, @"O.K.", @"K.O.")
}

// Ensures we eventually cover all K.O. scenarii.
test registry_ko_coverage() {
  scenario.check_coverage(
    all_registry_failures,
    scenario.ko(default_state(types.registry_token_name(), KindRegistry), step),
  )
}

fn run_registry(txs: List<Transaction>) {
  scenario.run(
    txs,
    validator_hash,
    handlers.treasury_registry.mint(seed, default_scope, _, _, _),
    handlers.treasury_registry.spend(seed, default_scope, _, _, _, _),
    scenario.into_withdraw_handler(default_registry_handler),
    scenario.into_publish_handler(default_registry_handler),
    scenario.into_vote_handler(default_registry_handler),
  )
}

// ----------------------------------------------------------------------------
// ----- Failing scenarii
// ----------------------------------------------------------------------------

// -------------------------------------------------------------------
// ----- Failing scenarii :: Mint
// -------------------------------------------------------------------

const unexpected_mint: String = @"· minted unexpected tokens"

const minted_too_many: String = @"· minted more than one token"

const unseeded_mint: String = @"· seed UTxO isn't consumed"

// -------------------------------------------------------------------
// ----- Failing scenarii :: Burn
// -------------------------------------------------------------------

const unauthorized_burn: String = @"· unauthorized burn"

const not_burning: String = @"· not burning anything"

const burn_before: String = @"· burn before"

// -------------------------------------------------------------------
// ----- Failing scenarii :: Update
// -------------------------------------------------------------------

const unauthorized_update: String = @"· unauthorized update"

const missing_token: String = @"· missing token (from inputs)"

const escaping_token: String = @"· escaping token"

const missing_datum: String = @"· missing inline datum"

const malformed_datum: String = @"· malformed datum"

const altered_datum: String = @"· altered datum"

const include_ref_script: String = @"· output with reference script"

const garbage_tokens: String = @"· output with garbage tokens"

// -------------------------------------------------------------------
// ----- Failing scenarii :: All
// -------------------------------------------------------------------

const all_scopes_failures: List<String> =
  [
    unexpected_mint, minted_too_many, unseeded_mint, unauthorized_burn,
    not_burning, burn_before, unauthorized_update, missing_token, escaping_token,
    missing_datum, malformed_datum, include_ref_script, garbage_tokens,
  ]

const all_registry_failures: List<String> =
  [
    unexpected_mint, minted_too_many, unseeded_mint, unauthorized_burn,
    not_burning, burn_before, unauthorized_update, missing_token, escaping_token,
    missing_datum, malformed_datum, altered_datum, include_ref_script,
    garbage_tokens,
  ]

// ----------------------------------------------------------------------------
// ----- Post-conditions
// ----------------------------------------------------------------------------

fn post_conditions(txs: List<Transaction>) {
  let len = list.length(txs)

  []
    |> scenario.classify(@"· immediate burn", len == 2)
    |> scenario.classify(@"· at least one update", len >= 3)
    |> scenario.classify(@"· more than one update", len > 3)
    |> scenario.classify(
        @"· consumes marginal UTxOs",
        has_marginal_utxos(list.drop(txs, 1)),
      )
    |> for_each(fuzz.label)
}

fn has_marginal_utxos(txs: List<Transaction>) {
  when txs is {
    [] -> False
    [head, ..tail] -> {
      let input <- list.any(head.inputs)
      let is_script =
        input.output.address.payment_credential == Credential.Script(
          validator_hash,
        )
      let has_token =
        assets.tokens(input.output.value, validator_hash) != dict.empty
      or {
        is_script && !has_token,
        has_marginal_utxos(tail),
      }
    }
  }
}

// ----------------------------------------------------------------------------
// ----- State
// ----------------------------------------------------------------------------

type Kind {
  KindScopes
  KindRegistry
}

type State {
  kind: Kind,
  labels: List<Label>,
  asset_name: AssetName,
  utxo: Option<Output>,
  done: Bool,
}

fn default_state(asset_name: AssetName, kind: Kind) -> State {
  State { kind, labels: [], asset_name, utxo: None, done: False }
}

/// Fork weights for the various scenarii, adjust as needed to explore every
/// scenarii and ensure roughly 50% of O.K. / K.O. split.
type Weights {
  scenario_inputs: Int,
  scenario_outputs: Int,
  scenario_mint: Int,
  scenario_burn: Int,
  scenario_validity: Int,
  scenario_signatories: Int,
}

const weights =
  Weights {
    scenario_inputs: 245,
    scenario_outputs: 235,
    scenario_mint: 210,
    scenario_burn: 230,
    scenario_validity: 230,
    scenario_signatories: 230,
  }

// ----------------------------------------------------------------------------
// ----- Step
// ----------------------------------------------------------------------------

fn step(st: State) -> Fuzzer<Scenario<State>> {
  if st.done {
    return(Scenario.Done)
  } else {
    when st.utxo is {
      None -> step_mint(st)
      Some(utxo) -> {
        // Here we handle the case where the contract has been bootstrapped (i.e.
        // mint happened), and we are now taking a second step which can be either
        // of:
        //
        // - Updating the scopes (via spending from & into it).
        // - Terminating the contract (burning the token).
        let toss <- and_then(fuzz.byte())
        if toss > 200 {
          step_burn(st, utxo)
        } else {
          step_update(st, utxo)
        }
      }
    }
  }
}

/// Here we handle the case where the contract is bootstrapped, and the
/// state defined with a minted token.
///
/// This step is necessary before any 'spend' can be authorized, and it
/// ensures the state is initialized correctly:
///
/// - token is locked by the contract
/// - output holds a datum
/// - nothing else is minted
/// - properly authenticated
fn step_mint(st: State) -> Fuzzer<Scenario<State>> {
  let (st, inputs) <-
    scenario.fork_and_then(
      weights.scenario_inputs,
      fn() { scenario_mint_inputs_baseline(st) },
      fn() { scenario_mint_inputs_no_seed_utxo(st) },
    )

  let (st, outputs) <-
    scenario.fork4_if_and_then(
      st.labels == [],
      weights.scenario_outputs,
      fn() { scenario_outputs_baseline(st) },
      fn() { scenario_outputs_missing_datum(st) },
      fn() { scenario_outputs_escaping_token(st) },
      fn() { scenario_outputs_malformed_datum(st) },
      fn() {
        scenario.fork(
          128,
          fn() { scenario_outputs_ref_script(st) },
          fn() { scenario_outputs_garbage_tokens(st) },
        )
      },
    )

  let (st, mint) <-
    scenario.fork2_if_and_then(
      st.labels == [],
      weights.scenario_mint,
      fn() { scenario_mint_baseline(st) },
      fn() { scenario_mint_too_many(st) },
      fn() { scenario_mint_unexpected(st) },
    )

  return(
    Scenario.Step(
      st.labels,
      State { ..st, labels: [] },
      Transaction {
        ..transaction.placeholder,
        inputs: inputs,
        outputs: outputs,
        mint: mint,
        redeemers: [mint_or_burn],
      },
    ),
  )
}

/// Once initialized, we should be able to update scopes in the contract as
/// many times as necessary. The update has roughly the same constraints as the
/// mint regarding the outputs, so we can re-use a lot of the scenarii.
fn step_update(st: State, own_resolved_input: Output) -> Fuzzer<Scenario<State>> {
  let own_input =
    OutputReference { transaction_id: "own_input", output_index: 0 }

  let own_utxo =
    Input { output_reference: own_input, output: own_resolved_input }

  let (st, inputs) <-
    scenario.fork_and_then(
      weights.scenario_inputs,
      fn() { scenario_update_inputs_baseline(st, own_utxo) },
      fn() { scenario_update_inputs_missing_token(st, own_input) },
    )

  let (st, outputs) <-
    scenario.fork4_if_and_then(
      st.labels == [],
      weights.scenario_outputs,
      fn() { scenario_outputs_baseline(st) },
      fn() { scenario_outputs_missing_datum(st) },
      fn() { scenario_outputs_escaping_token(st) },
      fn() { scenario_outputs_malformed_datum(st) },
      fn() {
        scenario.fork(
          128,
          fn() { scenario_outputs_ref_script(st) },
          fn() { scenario_outputs_garbage_tokens(st) },
        )
      },
    )

  let (st, extra_signatories) <-
    scenario.fork_if_and_then(
      st.labels == [],
      weights.scenario_signatories,
      fn() { scenario_signatories_baseline(st) },
      fn() { scenario_signatories_missing(st, unauthorized_update) },
    )

  return(
    Scenario.Step(
      st.labels,
      State { ..st, labels: [] },
      Transaction {
        ..transaction.placeholder,
        inputs: inputs,
        outputs: outputs,
        extra_signatories: extra_signatories,
        redeemers: spend_redeemers(inputs),
      },
    ),
  )
}

/// We're done with the contract, so we can get rid of the state and burn the
/// token. Note that we do not test for 'impossible cases' such as burning more
/// than one token or burning an asset that doesn't exist because those cases are
/// already caught as phase-1 validation failures.
fn step_burn(st: State, own_resolved_input: Output) -> Fuzzer<Scenario<State>> {
  let own_input =
    OutputReference { transaction_id: "own_input", output_index: 0 }

  let own_utxo =
    Input { output_reference: own_input, output: own_resolved_input }

  let (st, inputs) <- and_then(scenario_update_inputs_baseline(st, own_utxo))

  let (st, mint) <-
    scenario.fork_and_then(
      weights.scenario_burn,
      fn() { scenario_burn_baseline(st) },
      fn() { scenario_burn_none(st) },
    )

  let (st, validity_range) <-
    scenario.fork_if_and_then(
      st.labels == [],
      weights.scenario_validity,
      fn() { scenario_validity_range_baseline(st) },
      fn() { scenario_validity_range_before(st) },
    )

  let (st, extra_signatories) <-
    scenario.fork_if_and_then(
      st.labels == [],
      weights.scenario_signatories,
      fn() { scenario_signatories_baseline(st) },
      fn() { scenario_signatories_missing(st, unauthorized_burn) },
    )

  return(
    Scenario.Step(
      st.labels,
      State { ..st, done: True, labels: [] },
      Transaction {
        ..transaction.placeholder,
        inputs: inputs,
        extra_signatories: extra_signatories,
        mint: mint,
        validity_range: validity_range,
        redeemers: [mint_or_burn, ..spend_redeemers(inputs)],
      },
    ),
  )
}

// ----------------------------------------------------------------------------
// ----- Generators
// ----------------------------------------------------------------------------

// ------------------------------------------------------------------
// ----- Generators :: Inputs
// ------------------------------------------------------------------

fn scenario_mint_inputs_baseline(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs <-
    and_then(
      list_with(
        fuzz.list_between(cardano.input(), 0, 2),
        cardano.input_with(return(seed), cardano.output()),
      ),
    )
  return((st, inputs))
}

fn scenario_mint_inputs_no_seed_utxo(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs <-
    scenario.fork2_and_then(
      85,
      // No seed UTxO whatsoever.
      fn() { fuzz.list_between(cardano.input(), 0, 3) },
      // Wrong transaction id.
      fn() {
        list_with(
          fuzz.list_between(cardano.input(), 0, 2),
          {
            let id <- and_then(cardano.transaction_id())
            let input <-
              and_then(cardano.input_with(return(seed), cardano.output()))
            return(
              Input {
                ..input,
                output_reference: OutputReference {
                  ..input.output_reference,
                  transaction_id: id,
                },
              },
            )
          },
        )
      },
      // Wrong output index.
      fn() {
        list_with(
          fuzz.list_between(cardano.input(), 0, 2),
          {
            let index <-
              and_then(
                fuzz.such_that(
                  fuzz.int_at_least(0),
                  fn(i) { i != seed.output_index },
                ),
              )
            let input <-
              and_then(cardano.input_with(return(seed), cardano.output()))
            return(
              Input {
                ..input,
                output_reference: OutputReference {
                  ..input.output_reference,
                  output_index: index,
                },
              },
            )
          },
        )
      },
    )

  return((State { ..st, labels: [unseeded_mint, ..st.labels] }, inputs))
}

fn scenario_update_inputs_baseline(
  st: State,
  utxo: Input,
) -> Fuzzer<(State, List<Input>)> {
  let inputs <-
    and_then(
      list_with(
        fuzz.list_between(
          fuzz.either(
            cardano.input(),
            {
              // Allow inputs to be locked by a our script. Although only one can have the state token.
              // This demonstrates that we can collect UTxO sent by mistake to the contract.
              let our_input <- fuzz.and_then(cardano.input())

              let output = our_input.output

              // Sometimes, create fake UTxO that have datums of the right
              // shape, but don't hold the NFT.
              let datum <-
                fuzz.map(
                  fuzz.either(
                    return(output.datum),
                    fuzz.map(
                      when st.kind is {
                        KindScopes -> fuzz.map(scopes(), fn(s) { as_data(s) })
                        KindRegistry ->
                          fuzz.map(registry(), fn(r) { as_data(r) })
                      },
                      InlineDatum,
                    ),
                  ),
                )

              Input {
                ..our_input,
                output: Output {
                  ..output,
                  address: address.from_script(validator_hash),
                  datum: datum,
                },
              }
            },
          ),
          0,
          2,
        ),
        return(utxo),
      ),
    )

  return((st, inputs))
}

fn scenario_update_inputs_missing_token(
  st: State,
  output_reference: OutputReference,
) -> Fuzzer<(State, List<Input>)> {
  let output <-
    and_then(
      cardano.output_with(
        output_address_baseline(),
        cardano.value(assets.zero),
        cardano.datum(),
        cardano.reference_script(),
      ),
    )

  let utxo = Input { output_reference, output }

  let inputs <-
    and_then(list_with(fuzz.list_between(cardano.input(), 0, 2), return(utxo)))

  return((State { ..st, labels: [missing_token, ..st.labels] }, inputs))
}

// ------------------------------------------------------------------
// ----- Generators :: Outputs
// ------------------------------------------------------------------

fn output_address_baseline() -> Fuzzer<Address> {
  cardano.address_with(
    return(Credential.Script(validator_hash)),
    fuzz.option(cardano.stake_credential()),
  )
}

fn output_value_baseline(asset_name: AssetName) -> Fuzzer<Value> {
  let lovelace <- and_then(cardano.lovelace())
  cardano.value_with(
    lovelace,
    return([validator_hash]),
    fn(_policy_id) { return(asset_name) },
    fn(_policy_id, _asset_name) { return(1) },
  )
}

fn output_baseline(st: State) -> Fuzzer<Output> {
  cardano.output_with(
    output_address_baseline(),
    // if the token is missing from inputs, it can't possibly be in the
    // outputs (phase-1 rule).
    if list.has(st.labels, missing_token) {
      cardano.value(assets.zero)
    } else {
      output_value_baseline(st.asset_name)
    },
    output_datum_baseline(st),
    return(None),
  )
}

fn scenario_outputs_baseline(st: State) -> Fuzzer<(State, List<Output>)> {
  let output <- and_then(output_baseline(st))

  let outputs <-
    and_then(
      list_with(fuzz.list_between(cardano.output(), 0, 2), return(output)),
    )

  return((State { ..st, utxo: Some(output) }, outputs))
}

fn scenario_outputs_garbage_tokens(st: State) -> Fuzzer<(State, List<Output>)> {
  let output <- and_then(output_baseline(st))

  let poisoned_value <-
    and_then(
      fuzz.such_that(
        cardano.value(output.value),
        fn(value) { list.length(assets.policies(value)) > 2 },
      ),
    )

  let output = Output { ..output, value: poisoned_value }

  let outputs <-
    and_then(
      list_with(fuzz.list_between(cardano.output(), 0, 2), return(output)),
    )

  return(
    (
      State { ..st, labels: [garbage_tokens, ..st.labels], utxo: Some(output) },
      outputs,
    ),
  )
}

fn scenario_outputs_ref_script(st: State) -> Fuzzer<(State, List<Output>)> {
  let output <- and_then(output_baseline(st))
  let script_hash <- and_then(cardano.script_hash())

  let output = Output { ..output, reference_script: Some(script_hash) }

  let outputs <-
    and_then(
      list_with(fuzz.list_between(cardano.output(), 0, 2), return(output)),
    )

  return(
    (
      State {
        ..st,
        utxo: Some(output),
        labels: [include_ref_script, ..st.labels],
      },
      outputs,
    ),
  )
}

fn scenario_outputs_missing_datum(st: State) -> Fuzzer<(State, List<Output>)> {
  let output =
    cardano.output_with(
      output_address_baseline(),
      output_value_baseline(st.asset_name),
      fuzz.either(cardano.no_datum(), cardano.datum_hash()),
      cardano.reference_script(),
    )

  let outputs <-
    and_then(list_with(fuzz.list_between(cardano.output(), 0, 2), output))

  return((State { ..st, labels: [missing_datum, ..st.labels] }, outputs))
}

fn scenario_outputs_escaping_token(st: State) -> Fuzzer<(State, List<Output>)> {
  let output =
    cardano.output_with(
      cardano.address(),
      output_value_baseline(st.asset_name),
      output_datum_baseline(st),
      cardano.reference_script(),
    )

  let outputs <-
    and_then(list_with(fuzz.list_between(cardano.output(), 0, 2), output))

  return((State { ..st, labels: [escaping_token, ..st.labels] }, outputs))
}

fn scenario_outputs_malformed_datum(st: State) -> Fuzzer<(State, List<Output>)> {
  let (st, datum) <-
    and_then(
      when st.kind is {
        KindScopes -> scenario_datum_malformed_scopes(st)
        KindRegistry ->
          when st.utxo is {
            None -> scenario_datum_malformed_registry(st)
            Some(output) -> scenario_datum_altered_registry(st, output.datum)
          }
      },
    )

  let output =
    cardano.output_with(
      output_address_baseline(),
      output_value_baseline(st.asset_name),
      return(datum),
      cardano.reference_script(),
    )

  let outputs <-
    and_then(list_with(fuzz.list_between(cardano.output(), 0, 2), output))

  return((st, outputs))
}

// ------------------------------------------------------------------
// ----- Generators :: Datums
// ------------------------------------------------------------------

fn output_datum_baseline(st: State) -> Fuzzer<Datum> {
  when st.kind is {
    KindScopes ->
      // No restriction exists on scopes, they can change arbitrarily.
      fuzz.map(scopes(), fn(datum) { InlineDatum(as_data(datum)) })
    KindRegistry ->
      when st.utxo is {
        // When there's no previous output, the datum can be any registry whatsoever.
        None -> fuzz.map(registry(), fn(datum) { InlineDatum(as_data(datum)) })
        // If the state is already initialized, we must reuse the datum.
        Some(output) -> return(output.datum)
      }
  }
}

fn scenario_datum_malformed_scopes(st: State) -> Fuzzer<(State, Datum)> {
  let datum <-
    fuzz.map(
      fuzz.such_that(
        fuzz.data(),
        fn(data: Data) {
          if data is _: Scopes {
            False
          } else {
            True
          }
        },
      ),
    )

  (State { ..st, labels: [malformed_datum, ..st.labels] }, InlineDatum(datum))
}

fn scenario_datum_malformed_registry(st: State) -> Fuzzer<(State, Datum)> {
  let datum <-
    fuzz.map(
      fuzz.such_that(
        fuzz.data(),
        fn(data: Data) {
          if data is _: Registry {
            False
          } else {
            True
          }
        },
      ),
    )

  (State { ..st, labels: [malformed_datum, ..st.labels] }, InlineDatum(datum))
}

fn scenario_datum_altered_registry(
  st: State,
  current_datum: Datum,
) -> Fuzzer<(State, Datum)> {
  let datum <-
    fuzz.map(
      fuzz.such_that(
        registry(),
        fn(data: Registry) { InlineDatum(as_data(data)) != current_datum },
      ),
    )

  (State { ..st, labels: [altered_datum, ..st.labels] }, InlineDatum(datum))
}

// ------------------------------------------------------------------
// ----- Generators :: Mint
// ------------------------------------------------------------------

fn scenario_mint_baseline(st: State) -> Fuzzer<(State, Value)> {
  let mint <-
    and_then(
      cardano.value_with(
        assets.zero,
        return([validator_hash]),
        fn(_policy_id) { return(st.asset_name) },
        fn(_policy_id, _asset_name) { return(1) },
      ),
    )

  return((st, mint))
}

fn scenario_mint_too_many(st: State) -> Fuzzer<(State, Value)> {
  let mint <-
    and_then(
      cardano.value_with(
        assets.zero,
        return([validator_hash]),
        fn(_policy_id) { return(st.asset_name) },
        fn(_policy_id, _asset_name) { return(2) },
      ),
    )

  return((State { ..st, labels: [minted_too_many, ..st.labels] }, mint))
}

fn scenario_mint_unexpected(st: State) -> Fuzzer<(State, Value)> {
  let (st, base) <- and_then(scenario_mint_baseline(st))

  let mint <-
    and_then(
      cardano.value_with(
        base,
        return([validator_hash]),
        fn(_policy_id) { cardano.asset_name() },
        fn(_policy_id, _asset_name) { return(1) },
      ),
    )

  return((State { ..st, labels: [unexpected_mint, ..st.labels] }, mint))
}

// ------------------------------------------------------------------
// ----- Generators :: Burn
// ------------------------------------------------------------------

fn scenario_burn_baseline(st: State) -> Fuzzer<(State, Value)> {
  let burn <-
    and_then(
      cardano.value_with(
        assets.zero,
        return([validator_hash]),
        fn(_policy_id) { return(st.asset_name) },
        fn(_policy_id, _asset_name) { return(-1) },
      ),
    )

  return((st, burn))
}

fn scenario_burn_none(st: State) -> Fuzzer<(State, Value)> {
  let mint <-
    and_then(
      cardano.value_with(
        assets.zero,
        return([validator_hash]),
        fn(_policy_id) {
          fuzz.either(return(st.asset_name), cardano.asset_name())
        },
        fn(_policy_id, _asset_name) { fuzz.int_at_least(1) },
      ),
    )

  return((State { ..st, labels: [not_burning, ..st.labels] }, mint))
}

// ------------------------------------------------------------------
// ----- Generators :: Validity Range
// ------------------------------------------------------------------

fn scenario_validity_range_baseline(st: State) -> Fuzzer<(State, Interval<Int>)> {
  let lower_bound <- fuzz.map(fuzz.int_at_least(config.expiration))

  (st, interval.entirely_after(lower_bound))
}

fn scenario_validity_range_before(st: State) -> Fuzzer<(State, Interval<Int>)> {
  let validity_range <-
    fuzz.map(
      fuzz.either(
        fuzz.one_of([interval.everything, interval.after(config.expiration)]),
        fuzz.map(fuzz.int_between(0, config.expiration), interval.before),
      ),
    )

  (State { ..st, labels: [burn_before, ..st.labels] }, validity_range)
}

// ------------------------------------------------------------------
// ----- Generators :: Extra Signatories
// ------------------------------------------------------------------

fn scenario_signatories_baseline(
  st: State,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let signatories = config.pragma_general_assembly

  return((st, signatories))
}

fn scenario_signatories_missing(
  st: State,
  lbl: String,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let signatories <-
    and_then(
      fuzz.such_that(
        fuzz.sublist(config.pragma_general_assembly),
        fn(elems) { elems != config.pragma_general_assembly },
      ),
    )

  return((State { ..st, labels: [lbl, ..st.labels] }, signatories))
}

// ----------------------------------------------------------------------------
// ----- Helpers
// ----------------------------------------------------------------------------

const mint_or_burn: Pair<ScriptPurpose, Data> =
  Pair(ScriptPurpose.Mint(validator_hash), as_data(Void))

fn spend(utxo: OutputReference) -> Pair<ScriptPurpose, Data> {
  Pair(ScriptPurpose.Spend(utxo), as_data(Void))
}

fn spend_redeemers(inputs: List<Input>) -> Pairs<ScriptPurpose, Data> {
  inputs
    |> list.foldl(
        [],
        fn(input, redeemers) {
          if input.output.address.payment_credential == Credential.Script(
            validator_hash,
          ) {
            [spend(input.output_reference), ..redeemers]
          } else {
            redeemers
          }
        },
      )
}

fn scopes() -> Fuzzer<Scopes> {
  fuzz.map4(
    multisig_script(),
    multisig_script(),
    multisig_script(),
    multisig_script(),
    Scopes,
  )
}

fn registry() -> Fuzzer<Registry> {
  fuzz.map2(cardano.credential(), cardano.credential(), Registry)
}

fn multisig_script() -> Fuzzer<MultisigScript> {
  fuzz.map(cardano.verification_key_hash(), multisig.Signature)
}

fn list_with(rest: Fuzzer<List<a>>, elem: Fuzzer<a>) -> Fuzzer<List<a>> {
  let before <- and_then(rest)
  let within <- and_then(elem)
  let after <- fuzz.map(rest)
  list.concat(before, [within, ..after])
}
