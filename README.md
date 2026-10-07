# Functional Programming

The completed EC8206 submission for **Adeesha M.G.P (EG/2021/4385)** is in
[EG_2021_4385](EG_2021_4385/README.md). Run `make submission-test` to verify both
labs, the interpreter, and the imperative comparison. The original small starter
examples below remain available as a learning reference.

A small Haskell starter exploring pure functions, composition, higher-order
functions, and explicit error handling with `Maybe`.

## Develop

Requires GHC 9.6 or newer and GNU Make. No third-party Haskell packages are needed.

```sh
make run
make test
```

The example prints `220`, `Just 120`, and `10`. The test runner checks eight
cases, including empty input and negative factorial input. Builds treat compiler
warnings as errors. Run `make clean` to remove generated files.

In the prepared Codex cloud environment, activate the local toolchain first:

```sh
export PATH="/workspace/.haskell-toolchain/bin:$PATH"
cd /workspace/Functional-Programming
```

Start an interactive session with `ghci -isrc src/Functional.hs`.
The Cabal manifest is provided for editors and future package development;
the Make workflow builds offline using GHC's bundled `base` library.

## Files

- `src/Functional.hs`: reusable pure functions.
- `app/Main.hs`: runnable examples.
- `test/Main.hs`: dependency-free tests.

Extend the functions and add test cases as you learn.
