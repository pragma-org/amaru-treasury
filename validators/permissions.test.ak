use aiken/collection/list.{for_each}
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use aiken/fuzz.{and_then, constant as return}
use aiken/fuzz/scenario.{Label, Scenario}
use cardano/address.{Credential}
use cardano/assets.{Lovelace, PolicyId}
use cardano/fuzz as cardano
use cardano/transaction.{InlineDatum, Input, Output, ScriptPurpose, Transaction}
use config
use permissions.{Authorization} as handlers
use scope.{Scope, Scopes}
use sundae/multisig

// ---- Config

const permissions_validator_hash: ScriptHash =
  #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

const scopes_nft: PolicyId =
  #"99999999999999999999999999999999999999999999999999999999"

const aldo: VerificationKeyHash = #"a1d0"

const bob: VerificationKeyHash = #"b0be"

const lola: VerificationKeyHash = #"101a"

const zelda: VerificationKeyHash = #"2e11da"

fn run_as(scope: Scope, txs: List<Transaction>) {
  let default_handler =
    handlers.permissions.else(scopes_nft, scope, _)

  scenario.run(
    txs,
    permissions_validator_hash,
    scenario.into_mint_handler(default_handler),
    scenario.into_spend_handler(default_handler),
    into_withdraw_handler(scope, handlers.permissions.withdraw),
    scenario.into_publish_handler(default_handler),
    scenario.into_vote_handler(default_handler),
  )
}

// ---- Properties coverage

// Assess the frequency of O.K. vs K.O. scenarii, ensuring that we maintain a
// reasonable distribution as we complexify scenarii down the line.
test prop_permissions_distribution(
  outcome via scenario.report_coverage(
    // We reasonably expect the same coverage for all scopes.
    default_state(Scope.Ledger),
    step_standard,
  ),
) {
  fuzz.label_when(outcome == scenario.Ok, @"O.K.", @"K.O.")
}

// ---- Properties as Ledger

test prop_permissions_ledger_standard_ok(
  ok via scenario.ok(default_state(Scope.Ledger), step_standard),
) {
  run_as(Scope.Ledger, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_ledger_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Ledger), step_standard),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Ledger, ko)
}

// ---- Properties as Consensus

test prop_permissions_consensus_standard_ok(
  ok via scenario.ok(default_state(Scope.Consensus), step_standard),
) {
  run_as(Scope.Consensus, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_consensus_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Consensus), step_standard),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Consensus, ko)
}

// ---- Properties as Mercenaries

test prop_permissions_mercenaries_standard_ok(
  ok via scenario.ok(default_state(Scope.Mercenaries), step_standard),
) {
  run_as(Scope.Mercenaries, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_mercenaries_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Mercenaries), step_standard),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Mercenaries, ko)
}

// ---- Properties as Marketing

test prop_permissions_marketing_standard_ok(
  ok via scenario.ok(default_state(Scope.Marketing), step_standard),
) {
  run_as(Scope.Marketing, ok)
  for_each(ok, post_conditions)
}

test prop_permissions_marketing_standard_ko(
  (labels, ko) via scenario.ko(default_state(Scope.Marketing), step_standard),
) fail {
  for_each(list.unique(labels), fuzz.label)
  run_as(Scope.Marketing, ko)
}

// ----- Failing scenarii

const missing_scope_owner: String = @"· missing scope owner signature"

const missing_scopes: String = @"· missing scopes"

const malformed_scopes: String = @"· malformed scopes"

// ----- Post-conditions

fn post_conditions(scenario: Transaction) {
  let signatories = list.unique(scenario.extra_signatories)

  []
    |> scenario.classify(
        @"· more signers than necessary",
        list.length(signatories) > 2,
      )
    |> scenario.classify(
        @"· more than one reference inputs",
        list.length(scenario.reference_inputs) > 1,
      )
    |> for_each(fuzz.label)
}

// ----- State

type State {
  labels: List<Label>,
  scope: Scope,
  done: Bool,
}

fn default_state(scope: Scope) -> State {
  State { labels: [], scope, done: False }
}

type Weights {
  scenario_signatories: Int,
  scenario_reference_inputs: Int,
  scenario_scopes_datum: Int,
}

const weights =
  Weights {
    scenario_signatories: 172,
    scenario_reference_inputs: 212,
    scenario_scopes_datum: 212,
  }

// ----- Step :: standard

fn step_standard(st: State) -> Fuzzer<Scenario<State>> {
  if st.done {
    return(Scenario.Done)
  } else {
    let (st, reference_inputs) <-
      scenario.fork_and_then(
        weights.scenario_reference_inputs,
        fn() { scenario_ref_inputs_baseline(st) },
        fn() { scenario_ref_inputs_missing_scopes(st) },
      )

    let (st, withdrawals) <- and_then(scenario_withdrawals_baseline(st))

    let (st, redeemers) <- and_then(scenario_redeemers_baseline(st))

    let (st, extra_signatories) <-
      scenario.fork_and_then(
        weights.scenario_signatories,
        fn() { scenario_signatories_baseline(st) },
        fn() { scenario_signatories_missing_owner(st) },
      )

    return(
      Scenario.Step(
        st.labels,
        State { ..st, done: True, labels: [] },
        Transaction {
          ..transaction.placeholder,
          extra_signatories: extra_signatories,
          reference_inputs: reference_inputs,
          withdrawals: withdrawals,
          redeemers: redeemers,
        },
      ),
    )
  }
}

// ----- Generators

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
          ledger: multisig.Signature(aldo),
          consensus: multisig.Signature(bob),
          mercenaries: multisig.Signature(lola),
          marketing: multisig.Signature(zelda),
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

fn scenario_withdrawals_baseline(
  st: State,
) -> Fuzzer<(State, Pairs<Credential, Lovelace>)> {
  // Amount doesn't matter.
  let amount <- fuzz.map(fuzz.int_at_least(0))

  let withdrawals =
    [
      // Always include a withdrawal for our validator, otherwise nothing
      // is being tested...
      Pair(Credential.Script(permissions_validator_hash), amount),
    ]

  (st, withdrawals)
}

fn scenario_redeemers_baseline(
  st: State,
) -> Fuzzer<(State, Pairs<ScriptPurpose, Data>)> {
  return((st, [redeem_standard()]))
}

fn scenario_signatories_missing_owner(
  st: State,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let signatories <-
    fuzz.map(
      when st.scope is {
        Scope.Ledger -> fuzz.sublist([bob, lola, zelda])
        Scope.Consensus -> fuzz.sublist([aldo, lola, zelda])
        Scope.Mercenaries -> fuzz.sublist([aldo, bob, zelda])
        Scope.Marketing -> fuzz.sublist([aldo, bob, lola])
      },
    )

  (State { ..st, labels: [missing_scope_owner, ..st.labels] }, signatories)
}

fn scenario_signatories_baseline(
  st: State,
) -> Fuzzer<(State, List<VerificationKeyHash>)> {
  let signatories <-
    fuzz.map(
      when st.scope is {
        Scope.Ledger -> {
          let others <- and_then(non_empty_sublist([bob, lola, zelda]))
          return([aldo, ..others])
        }
        Scope.Consensus -> {
          let others <- and_then(non_empty_sublist([aldo, lola, zelda]))
          return([bob, ..others])
        }
        Scope.Mercenaries -> {
          let others <- and_then(non_empty_sublist([aldo, bob, zelda]))
          return([lola, ..others])
        }
        Scope.Marketing -> {
          let others <- and_then(non_empty_sublist([aldo, bob, lola]))
          return([zelda, ..others])
        }
      },
    )
  (st, signatories)
}

fn non_empty_sublist(elems: List<a>) -> Fuzzer<List<a>> {
  fuzz.such_that(fuzz.sublist(elems), fn(sigs) { sigs != [] })
}

// ----- Plumbing

fn redeem_standard() -> Pair<ScriptPurpose, Data> {
  Pair(
    ScriptPurpose.Withdraw(Credential.Script(permissions_validator_hash)),
    as_data(Authorization.Standard),
  )
}

fn into_withdraw_handler(
  scope: Scope,
  withdraw: fn(PolicyId, Scope, Authorization, Credential, Transaction) -> Bool,
) -> scenario.WithdrawHandler {
  fn(data: Data, account: Credential, transaction: Transaction) -> Bool {
    expect redeemer: Authorization = data
    withdraw(scopes_nft, scope, redeemer, account, transaction)
  }
}
