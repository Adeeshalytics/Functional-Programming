-- EC8206 | Adeesha M.G.P | EG/2021/4385
-- Pure syntax, evaluation, rewriting, and batch functions. Only base is needed.
module Expr where

import Data.Either (partitionEithers)

data Expr
  = Lit Double | Var String
  | Add Expr Expr | Sub Expr Expr | Mul Expr Expr | Div Expr Expr
  | Let String Expr Expr | If BExpr Expr Expr
  deriving (Eq, Show)

data BExpr
  = BLit Bool | Less Expr Expr | Equal Expr Expr
  | And BExpr BExpr | Or BExpr BExpr | Not BExpr
  deriving (Eq, Show)

type Env = [(String, Double)]

-- Numerical policy: accept finite Double values, reject NaN/infinity and overflow.
finite :: Double -> Bool
finite n = not (isNaN n || isInfinite n)

checked :: String -> Double -> Either String Double
checked reason n
  | finite n = Right n
  | otherwise = Left reason

eval :: Env -> Expr -> Either String Double
eval _ (Lit n) = checked "Non-finite literal" n
eval env (Var name) = case lookup name env of
  Nothing -> Left ("Undefined variable: " ++ name)
  Just n -> checked ("Non-finite variable: " ++ name) n
eval env (Add a b) = evalBinary (+) env a b
eval env (Sub a b) = evalBinary (-) env a b
eval env (Mul a b) = evalBinary (*) env a b
eval env (Div a b) = do
  numerator <- eval env a
  denominator <- eval env b
  case denominator of
    0 -> Left "Division by zero"
    _ -> checked "Non-finite arithmetic result" (numerator / denominator)
eval env (Let name definition body) = do
  value <- eval env definition
  eval ((name, value):env) body
eval env (If condition yes no) = do
  decision <- evalB env condition
  case decision of
    True -> eval env yes
    False -> eval env no

evalBinary :: (Double -> Double -> Double) -> Env -> Expr -> Expr -> Either String Double
evalBinary op env a b = do
  left <- eval env a
  right <- eval env b
  checked "Non-finite arithmetic result" (op left right)

evalB :: Env -> BExpr -> Either String Bool
evalB _ (BLit b) = Right b
evalB env (Less a b) = (<) <$> eval env a <*> eval env b
evalB env (Equal a b) = (==) <$> eval env a <*> eval env b
evalB env (And a b) = do
  left <- evalB env a
  case left of
    False -> Right False
    True -> evalB env b
evalB env (Or a b) = do
  left <- evalB env a
  case left of
    True -> Right True
    False -> evalB env b
evalB env (Not b) = not <$> evalB env b

-- A higher-order bottom-up traversal. Every constructor is explicit here;
-- -Wincomplete-patterns catches additions not handled by the traversal.
rewrite :: (Expr -> Expr) -> (BExpr -> BExpr) -> Expr -> Expr
rewrite rule boolRule = walk
  where
    walk (Lit n) = rule (Lit n)
    walk (Var x) = rule (Var x)
    walk (Add a b) = rule (Add (walk a) (walk b))
    walk (Sub a b) = rule (Sub (walk a) (walk b))
    walk (Mul a b) = rule (Mul (walk a) (walk b))
    walk (Div a b) = rule (Div (walk a) (walk b))
    walk (Let x a b) = rule (Let x (walk a) (walk b))
    walk (If c a b) = rule (If (walkB c) (walk a) (walk b))
    walkB (BLit b) = boolRule (BLit b)
    walkB (Less a b) = boolRule (Less (walk a) (walk b))
    walkB (Equal a b) = boolRule (Equal (walk a) (walk b))
    walkB (And a b) = boolRule (And (walkB a) (walkB b))
    walkB (Or a b) = boolRule (Or (walkB a) (walkB b))
    walkB (Not b) = boolRule (Not (walkB b))

-- Required algebraic identities, including x*0 -> 0. This mode assumes
-- discarded terms succeed. It is NOT an error-preserving optimizer.
simplify :: Expr -> Expr
simplify = rewrite algebraicRule safeBoolRule

algebraicRule :: Expr -> Expr
algebraicRule (Mul _ (Lit 0)) = Lit 0
algebraicRule (Mul (Lit 0) _) = Lit 0
algebraicRule (Sub a b) | a == b = Lit 0
algebraicRule e = safeRule e

-- Conservative optimizer: a term can be discarded only if evaluation in
-- the empty environment succeeds. Unknown variables therefore remain.
-- This may miss optimizations, but does not assume an environment's bindings.
simplifySafe :: Expr -> Expr
simplifySafe = rewrite safeRule safeBoolRule

safeRule :: Expr -> Expr
safeRule e | Right n <- eval [] e = Lit n
safeRule (Add e (Lit 0)) = e
safeRule (Add (Lit 0) e) = e
safeRule (Sub e (Lit 0)) = e
safeRule (Mul e (Lit 1)) = e
safeRule (Mul (Lit 1) e) = e
safeRule (Div e (Lit 1)) = e
safeRule (If (BLit True) yes _) = yes
safeRule (If (BLit False) _ no) = no
safeRule e = e

safeBoolRule :: BExpr -> BExpr
safeBoolRule e | Right b <- evalB [] e = BLit b
safeBoolRule (And (BLit True) e) = e
safeBoolRule (And e (BLit True)) = e
safeBoolRule (Or (BLit False) e) = e
safeBoolRule (Or e (BLit False)) = e
safeBoolRule (Not (Not e)) = e
safeBoolRule e = e

-- Currying: eval env :: Expr -> Either String Double is passed to map.
evalAll :: Env -> [Expr] -> [Either String Double]
evalAll env = map (eval env)

-- Common project scaffold: successful values only, in original order.
evalBatch :: Env -> [Expr] -> [Double]
evalBatch env = foldr keep [] . evalAll env
  where
    keep (Right n) rest = n:rest
    keep (Left _) rest = rest

-- filter selects; map transforms. Evaluate each input once in this pipeline.
successfulExpressions :: Env -> [Expr] -> [Expr]
successfulExpressions env = map fst . filter succeeded . map attach
  where
    attach e = (e, eval env e)
    succeeded (_, Right _) = True
    succeeded (_, Left _) = False

data BatchReport = BatchReport
  { successes :: Int, failures :: Int, resultValues :: [Double], errorMessages :: [String]
  } deriving (Eq, Show)

summarise :: Env -> [Expr] -> BatchReport
summarise env expressions =
  let (errors, values) = partitionEithers (evalAll env expressions)
  in BatchReport (length values) (length errors) values errors

-- Fully parenthesised output preserves grouping without precedence ambiguity.
pretty :: Expr -> String
pretty (Lit n) = show n
pretty (Var x) = x
pretty (Add a b) = binaryText "+" a b
pretty (Sub a b) = binaryText "-" a b
pretty (Mul a b) = binaryText "*" a b
pretty (Div a b) = binaryText "/" a b
pretty (Let x a b) = "(let " ++ x ++ " = " ++ pretty a ++ " in " ++ pretty b ++ ")"
pretty (If c a b) = "(if " ++ prettyB c ++ " then " ++ pretty a ++ " else " ++ pretty b ++ ")"

binaryText :: String -> Expr -> Expr -> String
binaryText op a b = "(" ++ pretty a ++ " " ++ op ++ " " ++ pretty b ++ ")"

prettyB :: BExpr -> String
prettyB (BLit b) = show b
prettyB (Less a b) = binaryText "<" a b
prettyB (Equal a b) = binaryText "==" a b
prettyB (And a b) = "(" ++ prettyB a ++ " && " ++ prettyB b ++ ")"
prettyB (Or a b) = "(" ++ prettyB a ++ " || " ++ prettyB b ++ ")"
prettyB (Not b) = "(not " ++ prettyB b ++ ")"

size :: Expr -> Int
size (Lit _) = 1
size (Var _) = 1
size (Add a b) = 1 + size a + size b
size (Sub a b) = 1 + size a + size b
size (Mul a b) = 1 + size a + size b
size (Div a b) = 1 + size a + size b
size (Let _ a b) = 1 + size a + size b
size (If c a b) = 1 + boolSize c + size a + size b

boolSize :: BExpr -> Int
boolSize (BLit _) = 1
boolSize (Less a b) = 1 + size a + size b
boolSize (Equal a b) = 1 + size a + size b
boolSize (And a b) = 1 + boolSize a + boolSize b
boolSize (Or a b) = 1 + boolSize a + boolSize b
boolSize (Not b) = 1 + boolSize b
