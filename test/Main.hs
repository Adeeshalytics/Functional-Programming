module Main (main) where

import Control.Monad (unless)
import Functional (applyTwice, factorial, sumOfEvenSquares)
import System.Exit (exitFailure)

main :: IO ()
main = do
  let checks =
        [ ("even squares", sumOfEvenSquares [1 .. 10] == 220)
        , ("empty list", sumOfEvenSquares [] == 0)
        , ("negative and odd inputs", sumOfEvenSquares [-4, -3, -2, 1] == 20)
        , ("factorial", factorial 5 == Just 120)
        , ("zero factorial", factorial 0 == Just 1)
        , ("negative factorial", factorial (-1) == Nothing)
        , ("higher-order function", applyTwice (+3) (4 :: Integer) == 10)
        , ("identity", applyTwice id "Haskell" == "Haskell")
        ]
  mapM_ (\(name, ok) -> putStrLn ((if ok then "PASS: " else "FAIL: ") ++ name)) checks
  unless (all snd checks) exitFailure
  putStrLn (show (length checks) ++ " tests passed.")
