use aiken/collection/list.{for_each}
use aiken/crypto.{ScriptHash}
use aiken/fuzz.{and_then, constant as return}
use aiken/fuzz/scenario.{Label, Scenario}
use cardano/address.{Address, Credential}
use cardano/assets.{AssetName, Value}
use cardano/fuzz as cardano
use cardano/transaction.{
  Datum, InlineDatum, Input, Output, OutputReference, ScriptPurpose, Transaction,
}
use config
use scope.{Scopes}
use sundae/multisig.{MultisigScript}
use traps as handlers

// ----------------------------------------------------------------------------
// ----- Config
// ----------------------------------------------------------------------------

const validator_hash: ScriptHash =
  #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

const seed: OutputReference =
  OutputReference { transaction_id: "seed", output_index: 99 }

const default_handler = handlers.scopes.else(seed, _)

// ----------------------------------------------------------------------------
// ----- Properties
// ----------------------------------------------------------------------------

test prop_scopes_ok(
  ok via scenario.ok(default_state(config.scopes_token_name), step),
) {
  run(ok)
}

test prop_scopes_ko(
  (labels, ko) via scenario.ko(default_state(config.scopes_token_name), step),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run(ko)
}

// Assess the frequency of O.K. vs K.O. scenarii, ensuring that we maintain a
// reasonable distribution as we complexify scenarii down the line.
test prop_scopes_scenarii_distribution(
  outcome via scenario.report_coverage(default_state(""), step),
) {
  fuzz.label_when(outcome == scenario.Ok, @"O.K.", @"K.O.")
}

fn run(txs: List<Transaction>) {
  scenario.run(
    txs,
    validator_hash,
    handlers.scopes.mint(seed, _, _, _),
    handlers.scopes.spend(seed, _, _, _, _),
    scenario.into_withdraw_handler(default_handler),
    scenario.into_publish_handler(default_handler),
    scenario.into_vote_handler(default_handler),
  )
}

// ----------------------------------------------------------------------------
// ----- Failing scenarii
// ----------------------------------------------------------------------------

const unexpected_mint: String = @"· minted unexpected tokens"

const minted_too_many: String = @"· minted more than one token"

const escaping_mint: String = @"· escaping minted token"

const unseeded_mint: String = @"· seed UTxO isn't consumed"

const missing_datum: String = @"· missing inline datum"

const malformed_datum: String = @"· malformed datum"

// ----------------------------------------------------------------------------
// ----- State
// ----------------------------------------------------------------------------

type State {
  labels: List<Label>,
  asset_name: AssetName,
  minted: Bool,
  done: Bool,
}

fn default_state(asset_name: AssetName) -> State {
  State { labels: [], asset_name, minted: False, done: False }
}

type Weights {
  scenario_inputs: Int,
  scenario_outputs: Int,
  scenario_mint: Int,
}

const weights =
  Weights { scenario_inputs: 220, scenario_outputs: 180, scenario_mint: 180 }

// ----------------------------------------------------------------------------
// ----- Step
// ----------------------------------------------------------------------------

fn step(st: State) -> Fuzzer<Scenario<State>> {
  if st.done {
    return(Scenario.Done)
  } else if !st.minted {
    // Here we handle the case where the contract is bootstrapped, and the
    // state defined with a minted token.
    //
    // This step is necessary before any 'spend' can be authorized, and it
    // ensures the state is initialized correctly:
    //
    // - token is locked by the contract
    // - output holds a datum
    // - nothing else is minted
    // - properly authenticated

    let (st, inputs) <-
      scenario.fork_and_then(
        weights.scenario_inputs,
        fn() { scenario_inputs_baseline(st) },
        fn() { scenario_inputs_no_seed_utxo(st) },
      )

    let (st, outputs) <-
      scenario.fork3_if_and_then(
        st.labels == [],
        weights.scenario_outputs,
        fn() { scenario_outputs_baseline(st) },
        fn() { scenario_outputs_missing_datum(st) },
        fn() { scenario_outputs_escaping_mint(st) },
        fn() { scenario_outputs_malformed_datum(st) },
      )

    let (st, mint) <-
      scenario.fork2_if_and_then(
        st.labels == [],
        weights.scenario_mint,
        fn() { scenario_mint_baseline(st) },
        fn() { scenario_mint_too_many(st) },
        fn() { scenario_mint_unexpected(st) },
      )

    let redeemers <- and_then(scenario_redeemers_baseline())

    return(
      Scenario.Step(
        st.labels,
        State { ..st, minted: True, labels: [] },
        Transaction {
          ..transaction.placeholder,
          inputs: inputs,
          outputs: outputs,
          mint: mint,
          redeemers: redeemers,
        },
      ),
    )
  } else {
    // TODO: one or more spend following the mint.
    return(Scenario.Done)
  }
}

// ----------------------------------------------------------------------------
// ----- Generators
// ----------------------------------------------------------------------------

// ------------------------------------------------------------------
// ----- Generators :: Inputs
// ------------------------------------------------------------------

fn scenario_inputs_baseline(st: State) -> Fuzzer<(State, List<Input>)> {
  let inputs <-
    and_then(
      list_with(
        fuzz.list_between(cardano.input(), 0, 2),
        cardano.input_with(return(seed), cardano.output()),
      ),
    )
  return((st, inputs))
}

fn scenario_inputs_no_seed_utxo(st: State) -> Fuzzer<(State, List<Input>)> {
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
            let id <- and_then(fuzz.bytearray_between(32, 32))
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
  cardano.value_with(
    assets.zero,
    return([validator_hash]),
    fn(_policy_id) { return(asset_name) },
    fn(_policy_id, _asset_name) { return(1) },
  )
}

fn output_datum_baseline() -> Fuzzer<Datum> {
  fuzz.map(scopes(), fn(datum) { InlineDatum(as_data(datum)) })
}

fn scenario_outputs_baseline(st: State) -> Fuzzer<(State, List<Output>)> {
  let output =
    cardano.output_with(
      output_address_baseline(),
      output_value_baseline(st.asset_name),
      output_datum_baseline(),
      cardano.reference_script(),
    )

  let outputs <-
    and_then(list_with(fuzz.list_between(cardano.output(), 0, 2), output))

  return((st, outputs))
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

fn scenario_outputs_escaping_mint(st: State) -> Fuzzer<(State, List<Output>)> {
  let output =
    cardano.output_with(
      cardano.address(),
      output_value_baseline(st.asset_name),
      output_datum_baseline(),
      cardano.reference_script(),
    )

  let outputs <-
    and_then(list_with(fuzz.list_between(cardano.output(), 0, 2), output))

  return((State { ..st, labels: [escaping_mint, ..st.labels] }, outputs))
}

fn scenario_outputs_malformed_datum(st: State) -> Fuzzer<(State, List<Output>)> {
  let output =
    cardano.output_with(
      output_address_baseline(),
      output_value_baseline(st.asset_name),
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
        InlineDatum,
      ),
      cardano.reference_script(),
    )

  let outputs <-
    and_then(list_with(fuzz.list_between(cardano.output(), 0, 2), output))

  return((State { ..st, labels: [malformed_datum, ..st.labels] }, outputs))
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
// ----- Generators :: Redeemers
// ------------------------------------------------------------------

fn scenario_redeemers_baseline() -> Fuzzer<Pairs<ScriptPurpose, Data>> {
  let data <- fuzz.map(fuzz.data())
  [Pair(ScriptPurpose.Mint(validator_hash), data)]
}

// ----------------------------------------------------------------------------
// ----- Helpers
// ----------------------------------------------------------------------------

fn scopes() -> Fuzzer<Scopes> {
  fuzz.map4(
    multisig_script(),
    multisig_script(),
    multisig_script(),
    multisig_script(),
    Scopes,
  )
}

fn multisig_script() -> Fuzzer<MultisigScript> {
  fuzz.map(fuzz.bytearray_between(28, 28), multisig.Signature)
}

fn list_with(rest: Fuzzer<List<a>>, elem: Fuzzer<a>) -> Fuzzer<List<a>> {
  let before <- and_then(rest)
  let within <- and_then(elem)
  let after <- fuzz.map(rest)
  list.concat(before, [within, ..after])
}
