# Journal :: Mercenaries

## Preamble

| Maintainer(s)            |                                                 [Pi Lanningham][] |
| :----------------------- | ----------------------------------------------------------------: |
| Credential               |        `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` |
| Treasury's stake address | [`stake17xrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yqhgk7k8`][] |
| Treasury's address       |                    [`addr1xxrh74lqhhxgzelf...3fkpz7rggqpymr9r`][] |
| Initial allocation       |                                                          ₳500,000 |

## Transactions

| ID           | [`dc67e79626a265ce808f1a7ca5fcfa5bdb0d7fb635691fc5bd82917930d8f266`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             initialize |
| Delta amount |                                                           +500,000 ADA |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 500,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

---

| ID           | [`b6aaa5bdfec89b0c52c338842971b12f525625dcfc7e899b4c8ebb15f8a45857`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                           `initialize` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`0729a234e4e12b945f06189ca479681e49ffcc116fb3713720bada72180fe27c`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                              `publish` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Publishing the initial registry datum identifying the treasury script. This is needed to avoid circular dependencies between on-chain validators. In particular, we define the original set of permissions for the mercenaries scope as follows:

- **reorganize**: 1 signature from:
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
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

[Pi Lanningham]: https://github.com/Quantumplation

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->

[`stake17xrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yqhgk7k8`]: https://cardanoscan.io/stakeKey/stake17xrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yqhgk7k8
[`addr1xxrh74lqhhxgzelf...3fkpz7rggqpymr9r`]: https://explorer.cardano.org/address/addr1xxrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yy80at7p0wvs9n7npx7upfd3htngmhlcz8lsz3fkpz7rggqpymr9r
[`dc67e79626a265ce808f1a7ca5fcfa5bdb0d7fb635691fc5bd82917930d8f266`]: https://explorer.cardano.org/tx/dc67e79626a265ce808f1a7ca5fcfa5bdb0d7fb635691fc5bd82917930d8f266
[`0729a234e4e12b945f06189ca479681e49ffcc116fb3713720bada72180fe27c`]: https://explorer.cardano.org/tx/0729a234e4e12b945f06189ca479681e49ffcc116fb3713720bada72180fe27c
[`b6aaa5bdfec89b0c52c338842971b12f525625dcfc7e899b4c8ebb15f8a45857`]: https://explorer.cardano.org/tx/b6aaa5bdfec89b0c52c338842971b12f525625dcfc7e899b4c8ebb15f8a45857
