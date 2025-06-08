# Contributing

## Testing

To run all tests:

```console
aiken check -P relative-to-tests
```

> [!WARNING]
>
> This may take a while (couple of minutes on a decent machine)... and possibly slow down your machine as tests are heavily parallelized and core threads are going to get real busy.
>
> If you see a line like:
>
> `Simplifying counterexample from ___ choices`
>
> ...that means one of the property test has failed and a counterexample (i.e. sequence of transactions that illustrates the failure) is being simplified down to what's essential. The simplification requires re-running **MANY** times the same test, and so takes a while. If you see a simplification from more than 1000 choices, you can go for a little walk or a coffee break.

### Sub-tests

- Only the traps validators:

  ```console
  aiken check -P relative-to-tests -m registry -m scopes
  ```

- Only the permissions validators:

  ```console
  aiken check -P relative-to-tests -m permissions
  ```
