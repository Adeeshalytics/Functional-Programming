# Understanding and explaining this submission

Adeesha M.G.P — EG/2021/4385

## 1. Higher-order functions

A function is higher-order when it receives or returns another function.
In `applyThrice f x`, `f` is an ordinary argument whose value is a function.
`applyThrice (+2) 1` means `(+2) ((+2) ((+2) 1))`, producing 7.

`pipeline [(+1), (*2)] 5` must produce 12. The fold starts at 5, applies the
first transformation to obtain 6, then the second to obtain 12. Reversing the
functions gives 11; that test catches an incorrect composition order.

Choose the tool by what the result needs:

| Function | Why it fits |
|---|---|
| map | Transform each item, e.g. Celsius to Fahrenheit |
| filter | Keep items satisfying a predicate, e.g. marks >= 40 |
| fold | Combine a whole list into a count, maximum, or pair |

For `sumAndCount`, the accumulator is `(total, count)`. Each item changes it to
`(total + item, count + 1)`. `foldl'` forces the pair constructor; explicit `seq`
also forces its numeric fields. That avoids accumulating deferred arithmetic
inside the pair during a large traversal. This does not make bounded `Int`
arithmetic immune to overflow.

Currying means `eval env` is itself a complete function value awaiting an Expr.
The same idea appears in `map (map toUpper . fst)`: the inner `map toUpper`
transforms the characters of each student's name.

Explain the empty-input contracts honestly: 0 is not a mathematical average
of no values; it is the compatibility convention. `averageMaybe []` expresses
absence with Nothing. Likewise minBound is a sentinel, not a unique absence
value, because a real input can contain minBound.

## 2. Pattern matching

The pattern `(_:x:_)` insists on at least two list elements. It ignores the
first and remaining tail, and binds the second to x. The wildcard equation
handles both [] and singleton lists, returning Nothing rather than throwing.

Guard order matters: mark >= 75 must be tested before mark >= 40. Reaching
the next guard already means all earlier guards failed. The eight boundary
tests distinguish all four thresholds.

Tree has two constructors, Leaf and Node. Each recursive function has a case
for each, and recurses on both subtrees of Node. In this representation Leaf is
an empty end. A single Node has two Leaf children, so countLeaves is 2, not 1.
For every finite tree here, leaves = nodes + 1. The tests check this invariant.

Mirror swaps both children recursively. Swapping twice restores the original:
`mirror (mirror tree) == tree`. This property tests more than one printed example.

## 3. Interpreter evaluation

Start with an expression tree, not an input string:

```haskell
Add (Lit 2) (Mul (Lit 3) (Lit 4))
```

Evaluate the children to 2 and 12, then add to obtain Right 14.
Expr enforces child types and constructor arity, but does not ensure a divisor
is nonzero or a variable exists. Those checks occur during evaluation.

`Either String Double` separates a failure message (Left) from a number (Right).
In a do block, a failed recursive evaluation stops the block through Either's
bind. The first operand's failure wins. Either does not force programmers to
handle every case correctly: incomplete patterns still need compiler checks.

For `Let "x" (Add (Var "x") (Lit 1)) (Var "x")` with outer x=5:

1. Evaluate the definition in the original environment: 5+1=6.
2. Prepend ("x",6) to a new list whose tail is the original environment.
3. Evaluate the body with that new binding: Right 6.
4. The caller's original x is still 5.

If evaluates only the selected branch. And/Or similarly short-circuit. Their
ordering is part of the language semantics, not just a performance choice.

## 4. The key simplification distinction

Try these in GHCi after loading Project/Expr.hs:

```haskell
let e = Mul (Var "missing") (Lit 0)
eval [] e
eval [] (simplify e)
eval [] (simplifySafe e)
```

The results are Left, Right 0, Left. Algebraically x*0 is zero, but an evaluator
that must evaluate x can encounter an error first. `simplify` deliberately
demonstrates the algebraic rule; its assumption is documented. `simplifySafe`
retains terms it cannot show are successfully evaluable independently of an
external environment. It still folds `(2+3)*4` to 20 and removes identities
that retain the evaluated term.

The Boolean version is equally important: `error && false` must still fail
because the left operand is evaluated first. `false && error` does not fail
because the right operand is not reached.

The safe pass may repeatedly evaluate closed subtrees and can do more work than
a compiler with a dedicated cached analysis. It is intentionally a small teaching
implementation, not an optimized production compiler. Generated cases improve
confidence, but do not prove correctness for all possible inputs.

## 5. Comparing with Python fairly

The Python evaluator also has correct scoping: it copies env before introducing
a local binding. Do not claim that Python inherently leaks bindings. The concrete
contrast is that Python requires choosing and implementing that discipline,
whereas the Haskell list is immutable by construction.

Python uses exceptions internally and catches expected evaluation errors at
the batch boundary. Haskell carries those failures in its return type. Both
propagate failures; they use different channels. Python's result list is built
with append; Haskell's batch pipeline returns fresh values through map/foldr.

Cross-language checks compare 16 outcomes, including missing variables,
division errors, shadowing, short-circuiting, and non-finite values.

## 6. Before handing in

- Run make test and read actual failures if any.
- Confirm the lecturer's original scaffold, project brief, and report limit.
- Be able to trace one successful evaluation and one error by hand.
- Explain the difference between pattern coverage and full program correctness.
- Explain why the two simplifiers intentionally have different contracts.
- Check the AI assistance statement against the lecturer's policy.
- Do not claim you personally developed or verified steps you have not reviewed.

Practice: add one test for an If condition that fails; explain why adding a new
Expr constructor should trigger compiler warnings in eval, rewrite, pretty,
and size; and describe how to remove minBound ambiguity without breaking the
provided lab API.
