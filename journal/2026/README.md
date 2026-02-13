## Configuration

For those interested in replaying the smart contract setup, here are some of the steps we went through:

- Declaring the 4 initial scopes owners, safe-guarded by PRAGMA's General Assembly: [11ace24a7b](https://explorer.cardano.org/tx/11ace24a7b0caad4a68a38ef2fff18185dc9ea604e84425dab487cae94e4cf54)
- Registering the 5 auxiliary permissions scripts a stake credentials (used by the main treasury script to add additional authorization requirements): [8e2b68bf66](https://explorer.cardano.org/tx/8e2b68bf660de451a5cea976eede80e0b252c080c4fb3e97c1e9dc5ab9ffd7f4)
- Publishing auxiliary permissions scripts as script reference, for later use in transactions: [25ba96f5de](https://explorer.cardano.org/tx/25ba96f5deb14bb5c56e7542d6a9ba8450f52cc698ebd74574e1a0525d861095)
- Declaring the 5 treasuries 'registries' (avoid circular dependencies in validator cross-references); locked by the 'registry' script: [e7b395a93d](https://explorer.cardano.org/tx/e7b395a93d49a17994d66df0e4778a01dee05e7711e6612f28d97b63e4e6311c)
- Publishing scope-based treasury scripts as script reference, for later use in transactions:
    - `core_development`:  [87ee53271f](https://explorer.cardano.org/tx/87ee53271fb41021efa13c2dbe2998c18ead07d32a6ab6dda184853ed7e39aae)
    - `ops_and_use_cases`: [660c0729b6](https://explorer.cardano.org/tx/660c0729b68bce67f62d4f1f3ae38082217e55915bb3e0d9222a67b2f9fd821c)
    - `network_compliance`: [810bfcbde8](https://explorer.cardano.org/tx/810bfcbde85ae72f27d7e8cd154c03c802de15d3fa0dd83a32a4b0fdba330b3c)
    - `middleware`: [ec31219173](https://explorer.cardano.org/tx/ec31219173fd4eb3cc3c2123e53425654c1122354ceafc247e7c32d278dad223)
    - `contingency`: [b25328336bb](https://explorer.cardano.org/tx/b25328336bbba240d5906952534e84bb8edf1a690f86a4160c38703396853c90)
- Registering all 5 treasuries as stake credentials, so that they can receive funds from the treasury, and delegating them to the always-abstain DRep: [f1a1737806](https://explorer.cardano.org/tx/f1a1737806037deb08da29411880a7379d06e335c1caf998a6dc4288db898a82)

The details of the construction of those transactions can be found in as [recipes](../../recipes).
