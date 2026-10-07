module Functional (sumOfEvenSquares, factorial, applyTwice) where

-- Compose pure functions: keep even numbers, square them, then sum.
sumOfEvenSquares :: [Integer] -> Integer
sumOfEvenSquares = sum . map (\n -> n * n) . filter even

-- Represent invalid input explicitly instead of throwing an exception.
factorial :: Integer -> Maybe Integer
factorial n
  | n < 0 = Nothing
  | otherwise = Just (product [1 .. n])

-- Functions can be passed as values.
applyTwice :: (a -> a) -> a -> a
applyTwice f = f . f
