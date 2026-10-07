module Main where

import Expr
import System.Exit (exitFailure)

sampleEnv :: Env
sampleEnv = [("x", 5), ("y", 2)]

samples :: [(String, Expr, Either String Double)]
samples =
  [ ("arithmetic", Add (Lit 2) (Mul (Lit 3) (Lit 4)), Right 14)
  , ("variables", Div (Sub (Var "x") (Lit 1)) (Var "y"), Right 2)
  , ("zero divisor", Div (Lit 10) (Sub (Var "x") (Lit 5)), Left "Division by zero")
  , ("missing variable", Add (Var "missing") (Lit 1), Left "Undefined variable: missing")
  , ("local binding", Let "a" (Lit 3) (Add (Mul (Var "a") (Var "a")) (Var "x")), Right 14)
  , ("shadowing", Let "x" (Lit 10) (Add (Var "x") (Var "y")), Right 12)
  , ("scope does not leak", Add (Let "x" (Lit 10) (Var "x")) (Var "x"), Right 15)
  , ("unselected branch", If (BLit True) (Lit 7) (Div (Lit 1) (Lit 0)), Right 7)
  , ("Boolean short circuit", If (And (BLit False) (Less (Div (Lit 1) (Lit 0)) (Lit 2))) (Lit 1) (Lit 9), Right 9)
  , ("strict let definition", Let "unused" (Div (Lit 1) (Lit 0)) (Lit 7), Left "Division by zero")
  ]

main :: IO ()
main = do
  putStrLn "Adeesha M.G.P | EG/2021/4385 | EC8206 interpreter"
  putStrLn ("Environment: " ++ show sampleEnv)
  mapM_ printSample samples
  let example = Mul (Var "missing") (Lit 0)
  putStrLn "\nWhy the simplification modes differ:"
  putStrLn (pretty example)
  print (eval sampleEnv example)
  putStrLn ("algebraic: " ++ pretty (simplify example))
  print (eval sampleEnv (simplify example))
  putStrLn ("safe: " ++ pretty (simplifySafe example))
  print (eval sampleEnv (simplifySafe example))
  putStrLn "\nBatch report:"
  print (summarise sampleEnv [e | (_, e, _) <- samples])
  let passed = length [() | (_, expression, expected) <- samples, eval sampleEnv expression == expected]
  putStrLn ("Demo checks: " ++ show passed ++ "/" ++ show (length samples) ++ " passed")
  if passed == length samples then pure () else exitFailure
  where
    printSample (label, expression, expected) = do
      putStrLn ("\n" ++ label ++ ": " ++ pretty expression)
      putStrLn ("expected: " ++ show expected)
      putStrLn ("actual:   " ++ show (eval sampleEnv expression))
