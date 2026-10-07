"""Adeesha M.G.P | EG/2021/4385: imperative comparison, Python standard library.

Tuple AST, explicit branching, exceptions, dictionary scopes, mutable batch list.
The implementation is correct: local binding copies the dictionary instead of
deliberately leaking state. Run python3 comparison.py; add --parity for GHC checks.
"""
import json
import math
from pathlib import Path
import subprocess
import sys
import unittest


class EvaluationError(Exception):
    pass


def checked(value, message):
    if not math.isfinite(value):
        raise EvaluationError(message)
    return value


def evaluate(env, node):
    tag = node[0]
    if tag == "lit":
        return checked(node[1], "Non-finite literal")
    if tag == "var":
        name = node[1]
        if name not in env:
            raise EvaluationError("Undefined variable: " + name)
        return checked(env[name], "Non-finite variable: " + name)
    if tag in ("add", "sub", "mul", "div"):
        left = evaluate(env, node[1])
        right = evaluate(env, node[2])
        if tag == "add":
            value = left + right
        elif tag == "sub":
            value = left - right
        elif tag == "mul":
            value = left * right
        else:
            if right == 0:
                raise EvaluationError("Division by zero")
            value = left / right
        return checked(value, "Non-finite arithmetic result")
    if tag == "let":
        value = evaluate(env, node[2])
        local_env = env.copy()
        local_env[node[1]] = value
        return evaluate(local_env, node[3])
    if tag == "if":
        decision = evaluate_bool(env, node[1])
        return evaluate(env, node[2] if decision else node[3])
    raise ValueError("Unknown expression tag: " + str(tag))


def evaluate_bool(env, node):
    tag = node[0]
    if tag == "bool":
        return node[1]
    if tag in ("less", "equal"):
        left = evaluate(env, node[1])
        right = evaluate(env, node[2])
        return left < right if tag == "less" else left == right
    if tag == "and":
        return evaluate_bool(env, node[1]) and evaluate_bool(env, node[2])
    if tag == "or":
        return evaluate_bool(env, node[1]) or evaluate_bool(env, node[2])
    if tag == "not":
        return not evaluate_bool(env, node[1])
    raise ValueError("Unknown Boolean tag: " + str(tag))


def outcome(env, node):
    try:
        return ("Right", evaluate(env, node))
    except EvaluationError as error:
        return ("Left", str(error))


def evaluate_batch(env, nodes):
    results = []
    for node in nodes:
        results.append(outcome(env, node))
    return results


def literal(n):
    return ("lit", n)


X, Y = ("var", "x"), ("var", "y")
ZERO_ERROR = ("div", literal(1), literal(0))
SAMPLES = [
    ("add", literal(2), ("mul", literal(3), literal(4))),
    ("div", ("sub", X, literal(1)), Y),
    ("div", literal(10), ("sub", X, literal(5))),
    ("add", ("var", "missing"), literal(1)),
    ("let", "a", literal(3), ("add", ("mul", ("var", "a"), ("var", "a")), X)),
    ("let", "x", literal(10), ("add", X, Y)),
    ("add", ("let", "x", literal(10), X), X),
    ("if", ("bool", True), literal(7), ZERO_ERROR),
    ("if", ("and", ("bool", False), ("less", ZERO_ERROR, literal(2))), literal(1), literal(9)),
    ("let", "unused", ZERO_ERROR, literal(7)),
    ("add", ("var", "first"), ("var", "second")),
    ("if", ("bool", False), ("var", "missing"), literal(8)),
    ("if", ("or", ("bool", True), ("less", ("var", "missing"), literal(0))), literal(6), literal(9)),
    ("mul", literal(1e308), literal(1e308)),
    literal(float("inf")),
    literal(float("nan")),
]
EXPECTED = [
    ("Right", 14), ("Right", 2), ("Left", "Division by zero"),
    ("Left", "Undefined variable: missing"), ("Right", 14), ("Right", 12),
    ("Right", 15), ("Right", 7), ("Right", 9), ("Left", "Division by zero"),
    ("Left", "Undefined variable: first"), ("Right", 8), ("Right", 6),
    ("Left", "Non-finite arithmetic result"), ("Left", "Non-finite literal"),
    ("Left", "Non-finite literal"),
]


class InterpreterTests(unittest.TestCase):
    def test_sample_outcomes(self):
        for index, (node, expected) in enumerate(zip(SAMPLES, EXPECTED), 1):
            with self.subTest(case=index):
                self.assertEqual(outcome({"x": 5, "y": 2}, node), expected)

    def test_scope_is_not_mutated(self):
        env = {"x": 5, "y": 2}
        self.assertEqual(evaluate(env, SAMPLES[5]), 12)
        self.assertEqual(env, {"x": 5, "y": 2})

    def test_definition_reads_outer_scope(self):
        node = ("let", "x", ("add", X, literal(1)), X)
        self.assertEqual(evaluate({"x": 5}, node), 6)

    def test_batch_keeps_errors_and_order(self):
        self.assertEqual(evaluate_batch({"x": 5, "y": 2}, SAMPLES), EXPECTED)

    def test_empty_batch(self):
        self.assertEqual(evaluate_batch({}, []), [])

    def test_nonfinite_binding(self):
        self.assertEqual(outcome({"x": float("inf")}, X), ("Left", "Non-finite variable: x"))

    def test_boolean_errors_and_not(self):
        self.assertFalse(evaluate_bool({}, ("not", ("bool", True))))
        self.assertTrue(evaluate_bool({}, ("equal", literal(2), literal(2))))
        with self.assertRaises(EvaluationError):
            evaluate_bool({}, ("and", ("less", ZERO_ERROR, literal(0)), ("bool", False)))

    def test_unknown_tag_is_rejected(self):
        with self.assertRaises(ValueError):
            evaluate({}, ("ad", literal(1), literal(2)))


def check_haskell_parity():
    project = Path(__file__).resolve().parent
    result = subprocess.run(
        ["runghc", "-i" + str(project), str(project / "Parity.hs")],
        capture_output=True, text=True, check=True,
    )
    actual = []
    for line in result.stdout.splitlines():
        tag, value = line.split(" ", 1)
        actual.append((tag, float(value) if tag == "Right" else json.loads(value)))
    python_results = evaluate_batch({"x": 5, "y": 2}, SAMPLES)
    if actual != python_results:
        raise AssertionError((actual, python_results))
    print(f"Cross-language parity: {len(actual)}/{len(SAMPLES)} outcomes agree")


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(InterpreterTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        sys.exit(1)
    if "--parity" in sys.argv:
        check_haskell_parity()
