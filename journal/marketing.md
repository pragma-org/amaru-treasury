# Journal :: Marketing

## Preamble

| Maintainer(s)            |                                                 [Damien Czapla][] |
| :----------------------- | ----------------------------------------------------------------: |
| Credential               |        `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` |
| Treasury's stake address | [`stake17xrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9ggg4u5y`][] |
| Treasury's address       |                    [`addr1xxrqac8khkprtpp2...juxe9c6v2shcjss3`][] |
| Initial allocation       |                                                          ₳100,000 |

## Transactions

| ID           | [`0290a5665bb01d0296b9be5b35e9e77a3db750d7a76df8ba1847adc3ef77a5e3`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             initialize |
| Delta amount |                                                           +100,000 ADA |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 500,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

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

[Damien Czapla]: https://github.com/Dam-CZ

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->

[`stake17xrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9ggg4u5y`]: https://cardanoscan.io/stakeKey/stake17xrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9ggg4u5y
[`addr1xxrqac8khkprtpp2...juxe9c6v2shcjss3`]: https://explorer.cardano.org/address/addr1xxrqac8khkprtpp2jz90mpkujjwye8dt6a9sjewrvjudx9vxpms0d0vzxkzz4yy2lkrde9yufjw6h46tp9juxe9c6v2shcjss3
[`0290a5665bb01d0296b9be5b35e9e77a3db750d7a76df8ba1847adc3ef77a5e3`]: https://explorer.cardano.org/tx/0290a5665bb01d0296b9be5b35e9e77a3db750d7a76df8ba1847adc3ef77a5e3
[`5697f433442317f04f539baecdf71fee01b3e8453c658a4d782648bc1e4f4490`]: https://explorer.cardano.org/tx/5697f433442317f04f539baecdf71fee01b3e8453c658a4d782648bc1e4f4490
[`bd215c2bf7e0577d1459c1d8da7c85aafbfa8d8b7293669cfabfa5563218972d`]: https://explorer.cardano.org/tx/bd215c2bf7e0577d1459c1d8da7c85aafbfa8d8b7293669cfabfa5563218972d
