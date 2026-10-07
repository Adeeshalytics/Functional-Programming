-- Machine-readable outcomes for cross-language comparison; run with runghc.
module Main where
import Expr

main :: IO ()
main = mapM_ (print . eval [("x",5),("y",2)])
  [ Add (Lit 2) (Mul (Lit 3) (Lit 4))
  , Div (Sub (Var "x") (Lit 1)) (Var "y")
  , Div (Lit 10) (Sub (Var "x") (Lit 5))
  , Add (Var "missing") (Lit 1)
  , Let "a" (Lit 3) (Add (Mul (Var "a") (Var "a")) (Var "x"))
  , Let "x" (Lit 10) (Add (Var "x") (Var "y"))
  , Add (Let "x" (Lit 10) (Var "x")) (Var "x")
  , If (BLit True) (Lit 7) (Div (Lit 1) (Lit 0))
  , If (And (BLit False) (Less (Div (Lit 1) (Lit 0)) (Lit 2))) (Lit 1) (Lit 9)
  , Let "unused" (Div (Lit 1) (Lit 0)) (Lit 7)
  , Add (Var "first") (Var "second")
  , If (BLit False) (Var "missing") (Lit 8)
  , If (Or (BLit True) (Less (Var "missing") (Lit 0))) (Lit 6) (Lit 9)
  , Mul (Lit 1e308) (Lit 1e308)
  , Lit (1/0)
  , Lit (0/0)
  ]
