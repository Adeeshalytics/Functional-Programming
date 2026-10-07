-- EC8206 | Adeesha M.G.P | EG/2021/4385
-- Exercise functions use patterns/guards, not if/else chains.
module Main where

import System.Exit (exitFailure)

-- Part A: specific patterns first; wildcard fallback last.
sinhalaDigit :: Int -> String
sinhalaDigit 0 = "binduwa"
sinhalaDigit 1 = "eka"
sinhalaDigit 2 = "deka"
sinhalaDigit _ = "?"

isWeekendDay :: String -> Bool
isWeekendDay "Sat" = True
isWeekendDay "Sun" = True
isWeekendDay _ = False

startsWithA :: String -> Bool
startsWithA ('A':_) = True
startsWithA _ = False

-- Part B: match structure, then use guards to check values.
gradeOf :: Int -> Char
gradeOf mark
  | mark >= 75 = 'A'
  | mark >= 65 = 'B'
  | mark >= 55 = 'C'
  | mark >= 40 = 'S'
  | otherwise = 'F'

quadrant :: (Int, Int) -> String
quadrant (x, y)
  | x > 0 && y > 0 = "I"
  | x < 0 && y > 0 = "II"
  | x < 0 && y < 0 = "III"
  | x > 0 && y < 0 = "IV"
  | otherwise = "axis"

secondElement :: [a] -> Maybe a
secondElement (_:x:_) = Just x
secondElement _ = Nothing

sameFirstTwo :: Eq a => [a] -> Bool
sameFirstTwo (x:y:_) = x == y
sameFirstTwo _ = False

-- Part C: recursion follows the constructors of the input.
countPositives :: [Int] -> Int
countPositives [] = 0
countPositives (x:xs)
  | x > 0 = 1 + countPositives xs
  | otherwise = countPositives xs

data Tree = Leaf | Node Tree Int Tree deriving (Eq, Show)

sample :: Tree
sample = Node (Node (Node Leaf 1 Leaf) 3 (Node Leaf 4 Leaf))
              5 (Node Leaf 8 (Node Leaf 9 Leaf))

-- Counts Leaf constructors (empty ends), NOT terminal value-bearing nodes.
countLeaves :: Tree -> Int
countLeaves Leaf = 1
countLeaves (Node left _ right) = countLeaves left + countLeaves right

-- Retains the common scaffold's Int result and minBound empty-tree convention.
treeMax :: Tree -> Int
treeMax Leaf = minBound
treeMax (Node left value right) = max value (max (treeMax left) (treeMax right))

treeMaxMaybe :: Tree -> Maybe Int
treeMaxMaybe Leaf = Nothing
treeMaxMaybe tree@(Node _ _ _) = Just (treeMax tree)

mirror :: Tree -> Tree
mirror Leaf = Leaf
mirror (Node left value right) = Node (mirror right) value (mirror left)

toList :: Tree -> [Int]
toList Leaf = []
toList (Node left value right) = toList left ++ [value] ++ toList right

nodeCount :: Tree -> Int
nodeCount Leaf = 0
nodeCount (Node left _ right) = 1 + nodeCount left + nodeCount right

tests :: [(String, Bool)]
tests =
  [ ("digit literals", map sinhalaDigit [0, 1, 2] == ["binduwa", "eka", "deka"])
  , ("digit wildcard", map sinhalaDigit [-1, 3, 9] == ["?", "?", "?"])
  , ("weekend", map isWeekendDay ["Sat", "Sun", "Mon", ""] == [True, True, False, False])
  , ("startsWithA contract", map startsWithA ["Adeesha", "amali", "", "B"] == [True, False, False, False])
  , ("grade boundaries", map gradeOf [39, 40, 54, 55, 64, 65, 74, 75] == "FSSCCBBA")
  , ("quadrants", map quadrant [(1,1), (-1,1), (-1,-1), (1,-1)] == ["I", "II", "III", "IV"])
  , ("axes", map quadrant [(0,0), (0,2), (2,0), (-2,0), (0,-2)] == replicate 5 "axis")
  , ("second element", secondElement [7,8,9 :: Int] == Just 8)
  , ("second singleton", secondElement [7 :: Int] == Nothing)
  , ("second empty", secondElement ([] :: [Int]) == Nothing)
  , ("same first two", sameFirstTwo [5,5,1 :: Int])
  , ("different first two", not (sameFirstTwo [5,4,5 :: Int]))
  , ("sameFirstTwo singleton", not (sameFirstTwo [5 :: Int]))
  , ("sameFirstTwo empty", not (sameFirstTwo ([] :: [Int])))
  , ("positive count", countPositives [3,-1,7,0] == 2)
  , ("positive count empty", countPositives [] == 0)
  , ("sample leaf count", countLeaves sample == 7)
  , ("empty tree leaf count", countLeaves Leaf == 1)
  , ("single node leaf count", countLeaves (Node Leaf 4 Leaf) == 2)
  , ("sample maximum", treeMax sample == 9)
  , ("negative tree maximum", treeMax (Node (Node Leaf (-8) Leaf) (-3) Leaf) == -3)
  , ("empty tree maximum convention", treeMax Leaf == minBound)
  , ("empty tree maximumMaybe", treeMaxMaybe Leaf == Nothing)
  , ("minBound is a valid node", treeMaxMaybe (Node Leaf minBound Leaf) == Just minBound)
  , ("mirror traversal", toList (mirror sample) == [9,8,5,4,3,1])
  , ("mirror involution", all (\t -> mirror (mirror t) == t) trees)
  , ("leaf count invariant", all (\t -> countLeaves t == nodeCount t + 1) trees)
  ]
  where
    trees = [Leaf, Node Leaf 1 Leaf, sample, Node sample (-3) Leaf]

runTests :: IO ()
runTests = do
  mapM_ printCheck tests
  putStrLn (show (length (filter snd tests)) ++ "/" ++ show (length tests) ++ " checks passed")
  case all snd tests of
    True -> pure ()
    False -> exitFailure
  where
    printCheck (name, ok)
      | ok = putStrLn ("PASS " ++ name)
      | otherwise = putStrLn ("FAIL " ++ name)

main :: IO ()
main = runTests
