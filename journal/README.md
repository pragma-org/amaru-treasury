# Journal

This folder contains financial journals for each of the managed treasuries:

- [ledger](./ledger.md)
- [consensus](./consensus.md)
- [mercenaries](./mercenaries.md)
- [marketing](./marketing.md)
- [contingency](./contingency.md)

Each journal is structured in a similar fashion and record transactions coming in and out of the treasuries. The aim is both to keep a human-readable trace of transactions happening around those accounts, as well as to ease the work of a financial auditors (or anyone really interested in auditing the trail of transactions). The next section describes the format of those journaling files.

There's an additional journal for recording [miscellaneous](./misc.md) transactions related to Amaru treasury management.

## Preamble

Each sub-journal shall present the following information as preamble:

| Maintainer(s)            | The name(s) of the scope's owner(s) / maintainer(s).                                                                             |
| ---                      | ---                                                                                                                              |
| Credential               | Blake2b-224 hash digest of either a Ed25519 public key or a Cardano's native script, corresponding to the owner(s)'s credential. |
| Treasury's stake address | The stake address / reward account corresponding to the managed treasury.                                                        |
| Treasury's address       | The full delegated address corresponding to the managed treasury.                                                                |
| Initial allocation       | An amount, in ada, corresponding to the initial treasury allocation                                                              |

## Transaction

Transactions shall be recorded in a most-recent-first list. Each item shall be separated by `---` and presented in the following form:

1. A structured header:

   | ID           | The transaction id (blake2b-256 hash digest of the transaction body)                                                       |
   | ---          | ---                                                                                                                        |
   | Type         | One of the types supported by the [on-chain metadata format][].                                                            |
   | Delta amount | The delta of managed assets; negative numbers are used for assets that leave the treasury.                                 |
   | Agreement?   | When disbursing to a vendor, a link to the [Remunerated Contributor Agreement][] between the scope's owner and the vendor. |

2. Followed by a body, plain markdown, serving as a description of the purpose or origin of the transaction, when known.

[on-chain metadata format]: https://github.com/SundaeSwap-finance/treasury-contracts/blob/main/offchain/src/metadata/spec.md
[Remunerated Contributor Agreement]: https://ipfs.io/ipfs/bafkreiabxyva5lfm6zztg7tnktxvvbbucljrce7hlrp4p6hropqzfaip3y
