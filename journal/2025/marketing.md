# Journal :: Marketing

## Preamble

| Maintainer(s)            | [Damien Czapla][]                                                                                        |
| :----------------------- | ----------------------------------------------------------------:                                        |
| Owner's credential       | `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e`                                               |
| Treasury's script hash   | `860ee0f6bd8235842a908afd86dc949c4c9dabd74b0965c364b8d315`                                               |
| Treasury's stake address | [`stake17xrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9ggg4u5y`][]                                        |
| Treasury's address       | [`addr1xxrqac8khkprtpp2...juxe9c6v2shcjss3`][]<br/>[`marketing@amaru`](https://pool.pm/$marketing@amaru) |
| Initial allocation       | ₳100,000                                                                                                 |
| Current balance          | ₳15.86 <br/> $445.08                                                                                     |

## Delivered Milestones

#### [Node Diversity Workshop and Summit][]

##### [Milestone 1](https://ipfs.io/ipfs/QmPy884FenC4Gr6d9tuwmkKJ4iVgrj6WAp2Rib9C1tTzrQ)

<details><summary>Node diversity & Cardano Summit planning, facilitation and recap</summary>

- https://forum.cardano.org/t/cardano-node-diversity-workshop-2-toulouse-22-23-september-2025/150304
- https://x.com/MinswapIntern/status/1988970111022104968
- https://x.com/andreassosilo/status/1988895839259861470
- https://x.com/elraulito/status/1988919116837630283
- https://x.com/btbfpark/status/1988586401974366338
</details>

## Transactions

| ID             | [`80ac843c71d5c4933877ab671bf377b34bc90abfc4df8287a3e92af806152c48`][] |
| :------------- | -----------------------------------------------------:                 |
| Type           | `sweep`                                                                |
| Delta amount   | -39,750 ADA                                                            |
| Agreement?     | N/A                                                                    |

Sweeping of the ADA leftovers from 2025, back into Cardano's treasury.

---

| ID           | [`89a3f90c728486b2c4dee46ef5efec95520f5ef8a140dbbe8e550ffca9448edf`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         | `disburse`                                                             |
| Delta amount | -50,000 USDM                                                           |
| Agreement?   | [Node Diversity Workshop And Summit][]                                 |

Disburse 50,000 USDM in payment of invoice from OpenTheLead for the Organisation of Node Diversity Workshop #2 and Cardano Summit 2025.

---

| ID           | [`977f4c921c1dff2799148048e8d604c682c8d44433fbb059e810c7306f4eb9bd`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                         +4,883.289360 USDM, +2.408 ADA |
| Agreement?   |                                                                    N/A |

Result of the last swap going through.

---

| ID           | [`402bda8c137d980fad7ecb9c920e2031e1c079c568dc4d03564d1f308876da15`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                        +19,701.003606 USDM, +9.836 ADA |
| Agreement?   |                                                                    N/A |

Result of 4 swaps going through.

---

| ID           | [`30e1eeb78af4817906813be8564a7c04f9bcbe8282d7db2c350da5185e4558ee`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             `disburse` |
| Delta amount |                                                            -29,000 ADA |
| Agreement?   |                                                                    N/A |

Securing another 25k USDM to have the value of the budget (50k$) on stablecoins with 5 swaps of +₳ 5,803.28.

---


| ID           | [`4502637f0ad3ff5ea948027270cb9e09b7bb9768bc3d26adc81918499229a902`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                        +25,860.787612 USDM, +2.306 ADA |
| Agreement?   |                                                                    N/A |

Result of the previous swap being credited back to the account alongside a deposit amount that was sent with the order to account for the minimum ada value on UTxO.

---

| ID           | [`60d4c29d273f822ddf6e3365387273d3eccd0f9ee442442b62b7f907787f0ee9`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             `disburse` |
| Delta amount |                                                            -31,250 ADA |
| Agreement?   |                                                                    N/A |

Securing a third of the budget, while the price of ADA is reasonably high for the period.

We cannot get a hold of the entire budget in USDM, because there's simply not enough liquidity on Cardano at the moment. But, the budget was planned with a rate of $0.5 per ADA; so we can currently secure more USDM with less ADA, which de-risk the devaluation of the budget due to price fluctuations. The swap order is parameterized with an owner script which enforces the same permissions as the 'disburse' operation (3 out of 4 signatures).

The final destination for the swap is the (marketing) treasury itself.

---

| ID           | [`0290a5665bb01d0296b9be5b35e9e77a3db750d7a76df8ba1847adc3ef77a5e3`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             initialize |
| Delta amount |                                                           +100,000 ADA |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 100,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

---

| ID           | [`bd215c2bf7e0577d1459c1d8da7c85aafbfa8d8b7293669cfabfa5563218972d`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                           `initialize` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`5697f433442317f04f539baecdf71fee01b3e8453c658a4d782648bc1e4f4490`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                              `publish` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Publishing the initial registry datum identifying the treasury script. This is needed to avoid circular dependencies between on-chain validators. In particular, we define the original set of permissions for the marketing scope as follows:

- **reorganize**: 1 signature from:
  - `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` (marketing)
- **disburse**: 3 signatures out of:
  - `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb` (ledger)
  - `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` (consensus)
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
  - `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` (marketing)
- **sweep**: 3 signatures out of:
  - `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb` (ledger)
  - `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` (consensus)
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
  - `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` (marketing)
- **fund**: disabled.

---

[Damien Czapla]: https://github.com/Dam-CZ

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->

[`stake17xrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9ggg4u5y`]: https://cardanoscan.io/stakeKey/stake17xrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9ggg4u5y
[`addr1xxrqac8khkprtpp2...juxe9c6v2shcjss3`]: https://explorer.cardano.org/address/addr1xxrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9vxpms0d0vzxkzz4yy2lkrde9yufjw6h46tp9juxe9c6v2shcjss3

[Node Diversity Workshop And Summit]: https://ipfs.io/ipfs/QmbjuHaCteEtqkLwV7c4TVejcf8gzg5rTFczuxKvX7qDX6

[`977f4c921c1dff2799148048e8d604c682c8d44433fbb059e810c7306f4eb9bd`]: https://explorer.cardano.org/tx/977f4c921c1dff2799148048e8d604c682c8d44433fbb059e810c7306f4eb9bd
[`402bda8c137d980fad7ecb9c920e2031e1c079c568dc4d03564d1f308876da15`]: https://explorer.cardano.org/tx/402bda8c137d980fad7ecb9c920e2031e1c079c568dc4d03564d1f308876da15
[`30e1eeb78af4817906813be8564a7c04f9bcbe8282d7db2c350da5185e4558ee`]: https://explorer.cardano.org/tx/30e1eeb78af4817906813be8564a7c04f9bcbe8282d7db2c350da5185e4558ee
[`4502637f0ad3ff5ea948027270cb9e09b7bb9768bc3d26adc81918499229a902`]: https://explorer.cardano.org/tx/4502637f0ad3ff5ea948027270cb9e09b7bb9768bc3d26adc81918499229a902
[`60d4c29d273f822ddf6e3365387273d3eccd0f9ee442442b62b7f907787f0ee9`]: https://explorer.cardano.org/tx/60d4c29d273f822ddf6e3365387273d3eccd0f9ee442442b62b7f907787f0ee9
[`0290a5665bb01d0296b9be5b35e9e77a3db750d7a76df8ba1847adc3ef77a5e3`]: https://explorer.cardano.org/tx/0290a5665bb01d0296b9be5b35e9e77a3db750d7a76df8ba1847adc3ef77a5e3
[`5697f433442317f04f539baecdf71fee01b3e8453c658a4d782648bc1e4f4490`]: https://explorer.cardano.org/tx/5697f433442317f04f539baecdf71fee01b3e8453c658a4d782648bc1e4f4490
[`bd215c2bf7e0577d1459c1d8da7c85aafbfa8d8b7293669cfabfa5563218972d`]: https://explorer.cardano.org/tx/bd215c2bf7e0577d1459c1d8da7c85aafbfa8d8b7293669cfabfa5563218972d
[`89a3f90c728486b2c4dee46ef5efec95520f5ef8a140dbbe8e550ffca9448edf`]: https://explorer.cardano.org/tx/89a3f90c728486b2c4dee46ef5efec95520f5ef8a140dbbe8e550ffca9448edf
[`80ac843c71d5c4933877ab671bf377b34bc90abfc4df8287a3e92af806152c48`]: https://explorer.cardano.org/tx/80ac843c71d5c4933877ab671bf377b34bc90abfc4df8287a3e92af806152c48

