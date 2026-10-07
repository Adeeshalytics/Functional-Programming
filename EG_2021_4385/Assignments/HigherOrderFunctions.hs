-- EC8206 | Adeesha M.G.P | EG/2021/4385
-- Run: runghc HigherOrderFunctions.hs, or ghci then runTests.
module Main where

import Data.Char (toUpper)
import Data.List (foldl')
import System.Exit (exitFailure)

-- Part A: functions are values; the list pipeline runs LEFT to RIGHT.
applyThrice :: (a -> a) -> a -> a
applyThrice f x = f (f (f x))

pipeline :: [a -> a] -> a -> a
pipeline fs initial = foldl' (\value transform -> transform value) initial fs

-- Part B: no explicit recursion in any of these definitions.
toFahrenheit :: [Double] -> [Double]
toFahrenheit = map (\c -> 9 * c / 5 + 32)

passing :: [Int] -> [Int]
passing = filter (>= 40)

countIf :: (a -> Bool) -> [a] -> Int
countIf predicate = foldr step 0
  where
    step item count
      | predicate item = count + 1
      | otherwise = count

-- The common scaffold uses Int. minBound is the identity for max on Int.
-- Empty input returns minBound; use maximumMaybe when absence must be explicit.
myMaximum :: [Int] -> Int
myMaximum = foldl' max minBound

maximumMaybe :: [Int] -> Maybe Int
maximumMaybe [] = Nothing
maximumMaybe (x:xs) = Just (foldl' max x xs)

-- A single traversal. Force BOTH fields, not just the pair constructor.
sumAndCount :: [Int] -> (Int, Int)
sumAndCount = foldl' step (0, 0)
  where
    step (total, count) x =
      let nextTotal = total + x
          nextCount = count + 1
      in nextTotal `seq` nextCount `seq` (nextTotal, nextCount)

-- Compatibility convention: average [] = 0. Optional helper records absence.
average :: [Int] -> Double
average xs = maybe 0 id (averageMaybe xs)

averageMaybe :: [Int] -> Maybe Double
averageMaybe xs = case sumAndCount xs of
  (_, 0) -> Nothing
  (total, count) -> Just (fromIntegral total / fromIntegral count)

-- Part C: operator sections and partially applied map/filter.
addVAT :: Double -> Double
addVAT = (* 1.18)

startsWithA :: [String] -> [String]
startsWithA = filter ((== "A") . take 1)

honourBoard :: [(String, Int)] -> [String]
honourBoard = map (map toUpper . fst) . filter ((>= 40) . snd)

tests :: [(String, Bool)]
tests =
  [ ("applyThrice", applyThrice (+2) (1 :: Int) == 7)
  , ("applyThrice on text", applyThrice ('A':) "" == "AAA")
  , ("pipeline order", pipeline [(+1), (*2)] (5 :: Int) == 12)
  , ("pipeline reverse order", pipeline [(*2), (+1)] (5 :: Int) == 11)
  , ("empty pipeline", pipeline [] "unchanged" == "unchanged")
  , ("Fahrenheit", toFahrenheit [0, 100, -40] == [32, 212, -40])
  , ("empty conversion", null (toFahrenheit []))
  , ("passing and boundary", passing [39, 40, 88, 12] == [40, 88])
  , ("empty passing", null (passing []))
  , ("countIf", countIf even [1..10 :: Int] == 5)
  , ("countIf no matches", countIf (>10) [1..5 :: Int] == 0)
  , ("countIf empty", countIf even ([] :: [Int]) == 0)
  , ("maximum", myMaximum [3, 9, 4] == 9)
  , ("negative maximum", myMaximum [-8, -2, -5] == -2)
  , ("empty maximum convention", myMaximum [] == minBound)
  , ("maximumMaybe absence", maximumMaybe [] == Nothing)
  , ("maximumMaybe minBound", maximumMaybe [minBound] == Just minBound)
  , ("sum and count", sumAndCount [10, 20, 30] == (60, 3))
  , ("sum and count empty", sumAndCount [] == (0, 0))
  , ("large sum and count", sumAndCount (replicate 100000 1) == (100000, 100000))
  , ("average", average [10, 20, 30] == 20)
  , ("average empty convention", average [] == 0)
  , ("averageMaybe absence", averageMaybe [] == Nothing)
  , ("VAT", abs (addVAT 100 - 118) < 1e-10)
  , ("startsWithA case and empty word", startsWithA ["", "Apple", "ant", "Ant"] == ["Apple", "Ant"])
  , ("honour board order and boundary", honourBoard [("adeesha", 40), ("nimal", 39), ("amali", 78)] == ["ADEESHA", "AMALI"])
  , ("empty honour board", null (honourBoard []))
  ]

runTests :: IO ()
runTests = do
  mapM_ printCheck tests
  putStrLn (show (length (filter snd tests)) ++ "/" ++ show (length tests) ++ " checks passed")
  if all snd tests then pure () else exitFailure
  where
    printCheck (name, ok) = putStrLn ((if ok then "PASS " else "FAIL ") ++ name)

main :: IO ()
main = runTests
