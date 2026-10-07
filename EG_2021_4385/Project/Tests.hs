module Main where

import Expr
import System.Exit (exitFailure)

env :: Env
env = [("x", 5), ("y", 2)]

tests :: [(String, Bool)]
tests =
  [ ("literal", eval env (Lit 42) == Right 42)
  , ("variable", eval env (Var "x") == Right 5)
  , ("addition", eval env (Add (Lit 2) (Lit 3)) == Right 5)
  , ("subtraction order", eval env (Sub (Lit 2) (Lit 3)) == Right (-1))
  , ("multiplication", eval env (Mul (Lit 3) (Lit 4)) == Right 12)
  , ("division order", eval env (Div (Lit 3) (Lit 4)) == Right 0.75)
  , ("nested zero divisor", eval env (Div (Lit 1) (Sub (Var "x") (Lit 5))) == Left "Division by zero")
  , ("missing variable", eval [] (Var "missing") == Left "Undefined variable: missing")
  , ("first error wins", eval [] (Add (Var "first") (Var "second")) == Left "Undefined variable: first")
  , ("let", eval env (Let "a" (Lit 3) (Mul (Var "a") (Var "a"))) == Right 9)
  , ("let shadow", eval env (Let "x" (Lit 10) (Var "x")) == Right 10)
  , ("let no leak", eval env (Add (Let "x" (Lit 10) (Var "x")) (Var "x")) == Right 15)
  , ("definition sees outer scope", eval env (Let "x" (Add (Var "x") (Lit 1)) (Var "x")) == Right 6)
  , ("unused definition still evaluated", eval env (Let "a" (Div (Lit 1) (Lit 0)) (Lit 7)) == Left "Division by zero")
  , ("if true skips bad branch", eval [] (If (BLit True) (Lit 7) (Var "missing")) == Right 7)
  , ("if false skips bad branch", eval [] (If (BLit False) (Var "missing") (Lit 8)) == Right 8)
  , ("comparison", evalB env (Less (Var "y") (Var "x")) == Right True)
  , ("equality", evalB env (Equal (Var "x") (Lit 5)) == Right True)
  , ("and short circuit", evalB [] (And (BLit False) badBool) == Right False)
  , ("or short circuit", evalB [] (Or (BLit True) badBool) == Right True)
  , ("not", evalB [] (Not (BLit True)) == Right False)
  , ("reject infinity", eval [] (Lit (1/0)) == Left "Non-finite literal")
  , ("reject NaN", eval [] (Lit (0/0)) == Left "Non-finite literal")
  , ("reject non-finite binding", eval [("x", 1/0)] (Var "x") == Left "Non-finite variable: x")
  , ("reject overflow", eval [] (Mul (Lit 1e308) (Lit 1e308)) == Left "Non-finite arithmetic result")
  , ("algebraic additive identity", simplify (Add (Var "x") (Lit 0)) == Var "x")
  , ("algebraic multiplicative identity", simplify (Mul (Lit 1) (Var "x")) == Var "x")
  , ("required algebraic annihilator", simplify (Mul (Var "x") (Lit 0)) == Lit 0)
  , ("constant folding", simplifySafe (Mul (Add (Lit 2) (Lit 3)) (Lit 4)) == Lit 20)
  , ("safe mode keeps missing-variable failure", preserves [] (Mul (Var "missing") (Lit 0)))
  , ("safe mode keeps zero-divisor failure", preserves [] (Mul (Div (Lit 1) (Lit 0)) (Lit 0)))
  , ("safe mode keeps self-subtraction error", preserves [] (Sub (Var "missing") (Var "missing")))
  , ("safe mode keeps error && false", preserves [] (If (And badBool (BLit False)) (Lit 1) (Lit 2)))
  , ("safe mode keeps error || true", preserves [] (If (Or badBool (BLit True)) (Lit 1) (Lit 2)))
  , ("safe mode keeps unused let error", preserves [] (Let "a" (Div (Lit 1) (Lit 0)) (Lit 7)))
  , ("safe mode folds closed local binding", simplifySafe (Let "a" (Lit 2) (Mul (Var "a") (Lit 0))) == Lit 0)
  , ("algebraic limitation explicitly demonstrated", eval [] risky == Left "Undefined variable: missing" && eval [] (simplify risky) == Right 0)
  , ("ordered batch outcomes", evalAll env batch == [Right 1, Left "Undefined variable: missing", Left "Division by zero", Right 7])
  , ("ordered successful values", evalBatch env batch == [1,7])
  , ("filter expressions", successfulExpressions env batch == [Lit 1, Add (Var "x") (Var "y")])
  , ("batch report", summarise env batch == BatchReport 2 2 [1,7] ["Undefined variable: missing", "Division by zero"])
  , ("empty batch", summarise [] [] == BatchReport 0 0 [] [])
  , ("safe preservation over generated corpus", all (\(scope,e) -> preserves scope e) generatedCases)
  , ("safe idempotence over generated corpus", all (\e -> simplifySafe (simplifySafe e) == simplifySafe e) corpus)
  , ("safe size never grows over generated corpus", all (\e -> size (simplifySafe e) <= size e) corpus)
  ]
  where
    risky = Mul (Var "missing") (Lit 0)
    batch = [Lit 1, Var "missing", Div (Lit 1) (Lit 0), Add (Var "x") (Var "y")]

badBool :: BExpr
badBool = Less (Div (Lit 1) (Lit 0)) (Lit 0)

preserves :: Env -> Expr -> Bool
preserves scope e = eval scope e == eval scope (simplifySafe e)

-- Deterministic bounded generation, not exhaustive testing or a formal proof.
-- Includes missing variables and zero divisors; all inputs here have finite literals.
next :: Integer -> Integer
next seed = (1664525 * seed + 1013904223) `mod` 4294967296

generate :: Int -> Integer -> Expr
generate depth seed
  | depth == 0 = atom
  | otherwise = case seed `mod` 10 of
      0 -> atom
      1 -> Var "missing"
      2 -> Add left right
      3 -> Sub left right
      4 -> Mul left right
      5 -> Div left right
      6 -> Let "x" left right
      7 -> If (Less left right) right left
      8 -> If (And (BLit False) (Less left right)) left right
      _ -> Mul left (Lit 0)
  where
    atom = case seed `mod` 4 of
      0 -> Var "x"
      1 -> Var "y"
      _ -> Lit (fromIntegral (seed `mod` 21 - 10) / 4)
    left = generate (depth - 1) (next seed)
    right = generate (depth - 1) (next (next seed))

corpus :: [Expr]
corpus = map (generate 4) [1..500]

generatedCases :: [(Env, Expr)]
generatedCases = [(scope, e) | scope <- [[], env, [("x", -3), ("y", 0)]], e <- corpus]

main :: IO ()
main = do
  mapM_ (\(name, ok) -> putStrLn ((if ok then "PASS " else "FAIL ") ++ name)) tests
  putStrLn (show (length (filter snd tests)) ++ "/" ++ show (length tests) ++ " checks passed")
  putStrLn ("Generated corpus: " ++ show (length corpus) ++ " trees; " ++ show (length generatedCases) ++ " environment/expression preservation checks")
  let errorCount = length [() | (scope,e) <- generatedCases, Left _ <- [eval scope e]]
  putStrLn ("Generated cases returning errors: " ++ show errorCount)
  if all snd tests then pure () else exitFailure
