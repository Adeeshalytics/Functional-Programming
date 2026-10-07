# EC8206 — Adeesha M.G.P

**Registration:** EG/2021/4385

This package contains both coding labs and the arithmetic expression interpreter
project. The lab contracts follow the supplied lecture decks and the common
scaffold present in the reference submissions. The original project brief was
not supplied; confirm its exact required signatures, extensions, report limits,
and submission rules before handing this in.

## Run everything

Requires GHC 9.6+ with its bundled `base`, GNU Make, and Python 3. No external
Haskell or Python packages are needed to run the submission.

```sh
cd EG_2021_4385
make test
make demo
```

In the prepared Codex cloud machine, first activate its local compiler:

```sh
export PATH="/workspace/.haskell-toolchain/bin:$PATH"
cd /workspace/Functional-Programming/EG_2021_4385
make test
```

Every Haskell entry point is compiled with
`-Wall -Wincomplete-patterns -Werror`. Separate output directories prevent the
standalone labs' `Main` modules from colliding. Test failures exit nonzero.

Without Make, run the labs separately:

```sh
runghc Assignments/HigherOrderFunctions.hs
runghc Assignments/PatternMatching.hs
runghc -iProject Project/Tests.hs
runghc -iProject Project/Main.hs
python3 -B Project/comparison.py --parity
```

For a lab workshop, load its file in GHCi and call `runTests`:

```sh
ghci Assignments/HigherOrderFunctions.hs
```

## Deliverables

- `Assignments/HigherOrderFunctions.hs`: Parts A-C, with 27 checks.
- `Assignments/PatternMatching.hs`: Parts A-C, with 27 checks.
- `Project/Expr.hs`: syntax, evaluation, two rewrite modes, batch processing.
- `Project/Main.hs`: ten expected/actual examples and a batch demonstration.
- `Project/Tests.hs`: 45 checks, including properties on 500 generated trees.
- `Project/Parity.hs`: 16 machine-readable Haskell outcomes for comparison.
- `Project/comparison.py`: working imperative counterpart, eight test methods
  (including 16 sample subcases) and cross-language comparison.
- `Project/Project_Report.pdf`: four-page report.
- `Project/REPORT.md`: editable report source.
- `Evidence/`: captured validation and demonstration output.
- `Guide/STUDY_GUIDE.md`: explanations, exercises, and review checklist.

## Contracts and limitations

The lab exercise functions retain their common scaffold signatures. `myMaximum []`
and `treeMax Leaf` return `minBound`; `average []` returns 0 as a documented
compatibility convention. Optional `maximumMaybe`, `treeMaxMaybe`, and
`averageMaybe` helpers represent absence explicitly. `Int` arithmetic is bounded:
these lab sum functions do not promise overflow detection.

The pattern lab counts `Leaf` constructors, so its sample has seven leaves.
`sinhalaDigit` maps 0-2 to the specified names and uses `"?"` otherwise;
weekends use `"Sat"` and `"Sun"`, and starts-with-A is case-sensitive.

The interpreter accepts finite `Double` values and reports NaN, infinity, and
arithmetic overflow as `Left` errors. Underflow and normal floating-point rounding
remain possible. Boolean equality is exact numeric equality, not approximate
equality. This is a tree interpreter, not a text parser or interactive REPL.

`simplify` demonstrates algebraic identities requested by the reference scaffold.
It can discard errors and is not used as an error-preserving optimizer.
`simplifySafe` is the conservative alternative: unknown or failing terms are
retained. The report and tests demonstrate the difference. The generated tests
are finite evidence, not a proof over all trees, environments, or resource limits.

## AI assistance and review

To regenerate the PDF, edit `Project/REPORT.md` and run
`python3 Project/build_report.py`. This optional step needs ReportLab and
DejaVu Sans/Mono TrueType fonts at `/usr/share/fonts/truetype/dejavu`, as
provided in the prepared environment. PDF regeneration is separate from running
the submitted Haskell/Python programs.

OpenAI Codex assisted in generating the source, tests, report, and supporting
materials, and executed the documented validation in the cloud environment.
The friends' submissions were reviewed as reference material; they are not
included in this package. Review and understand the work before submission,
and follow the lecturer's actual policy on assisted work.
