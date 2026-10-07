module Main (main) where

import Functional (applyTwice, factorial, sumOfEvenSquares)

main :: IO ()
main = do
  putStrLn ("Sum of even squares in [1..10]: " ++ show (sumOfEvenSquares [1 .. 10]))
  putStrLn ("Factorial of 5: " ++ show (factorial 5))
  putStrLn ("Apply (+3) twice to 4: " ++ show (applyTwice (+3) (4 :: Integer)))
