module Air.Light where


import Control.Arrow ((&&&), (>>>), (<<<))
import Control.Category (Category)
import Data.Char
import Data.Foldable (elem, foldl, foldl', toList, Foldable)
import Data.Function (on)
import Debug.Trace
import Prelude hiding ((.), (^), (>), (<), (/), (-), elem, foldl, foldl1, length, drop)
import qualified Prelude as P
import System.FilePath ((</>))
import qualified Data.Array as A
import qualified Data.List as L
import qualified Data.Map as M
import qualified Data.Set as S
import Data.List ( genericDrop, genericLength )

import qualified Control.Monad as Monad

import Control.Concurrent
import System.Exit ( exitWith, ExitCode(ExitSuccess) )


-- base DSL
{-# INLINE (.) #-}
(.) :: a -> (a -> b) -> b
a . f = f a
infixl 9 .

(>) :: (Category cat) => cat a b -> cat b c -> cat a c
(>) = (>>>)
infixl 8 >

(<) :: (Category cat) => cat b c -> cat a b -> cat a c
(<) = (<<<)
infixr 8 <

(^) :: (Functor f) => f a -> (a -> b) -> f b
(^) = flip fmap
infixl 8 ^

(/) :: FilePath -> FilePath -> FilePath
(/) = (</>)
infixl 5 /

{-# INLINE (-) #-}
(-) :: (a -> b) -> a -> b
f - x =  f x
infixr 0 -

(<->) :: (Num a) => a -> a -> a
(<->) = (P.-)
infix 6 <->


-- List
join :: [a] -> [[a]] -> [a]
join = L.intercalate

join' :: [[a]] -> [a]
join' = concat

first, second, third, forth, fifth :: (Show a) => [a] -> a
sixth, seventh, eighth, ninth, tenth :: (Show a) => [a] -> a
first   = head
second  = at 1
third   = at 2
forth   = at 3
fifth   = at 4
sixth   = at 5
seventh = at 6
eighth  = at 7
ninth   = at 8
tenth   = at 10

-- Set requires Ord instance, so use nub when
-- xs is not comparable
unique :: (Ord a) => [a] -> [a]
unique = to_set > to_list

is_unique :: (Ord a) => [a] -> Bool
is_unique xs = xs.unique.length == xs.length

same :: (Ord a) => [a] -> Bool
same = unique > length > is 1

times :: b -> Int -> [b]
times = flip replicate

upto :: (Enum a) => a -> a -> [a]
upto = flip enumFromTo

downto :: (Num t, Enum t) => t -> t -> [t]
downto m n = [n, n <-> 1.. m]

remove_at :: Int -> [a] -> [a]
remove_at n xs = xs.take n ++ xs.drop (n+1)

insert_at, replace_at :: Int -> a -> [a] -> [a]
insert_at n x xs  = splitted.fst ++ [x] ++ splitted.snd 
  where splitted  = xs.splitAt n
replace_at n x xs = xs.take n ++ [x] ++ xs.drop (n+1)

slice :: Int -> Int -> [a] -> [a]
slice l r = take r > drop l

cherry_pick :: [Int] -> [a] -> [a]
cherry_pick ids xs  = ids.map(xs !!)

reduce, reduce' :: (a -> a -> a) -> [a] -> a
reduce = L.foldl1
reduce' = L.foldl1'

inject, inject' :: (Foldable t) => a -> (a -> b -> a) -> t b -> a
inject  = flip foldl
inject' = flip foldl'

none_of :: (a -> Bool) -> [a] -> Bool
none_of f = any f > not

select, reject :: (a -> Bool) -> [a] -> [a]
select   = filter
reject f = filter (f > not)

inner_map :: (a -> b) -> [[a]] -> [[b]]
inner_map f = map (map f)

inner_reduce :: (a -> a -> a) -> [[a]] -> [a]
inner_reduce f = map (reduce f)

inner_inject :: (Foldable t) => a -> (a -> b -> a) -> [t b] -> [a]
inner_inject x f = map (inject x f)

label_by :: (a -> c) -> [a] -> [(c, a)]
label_by f = map (f &&& id)

labeling :: (a -> c') -> [a] -> [(a, c')]
labeling f = map(id &&& f)

in_group_of :: Int -> [t] -> [[t]]
in_group_of _ [] = []
in_group_of n xs = h : t.in_group_of(n) where (h, t) = xs.splitAt(n)

split_to :: Int -> [a] -> [[a]]
split_to n xs = xs.in_group_of(size) where
  l = xs.length
  size = if l P.< n then 1 else l `div` n

apply, send_to :: a -> (a -> b) -> b
apply x f = f x
send_to   = apply

let_receive :: (a -> b -> c) -> b -> a -> c
let_receive f = flip f

map_send_to :: a -> [a -> b] -> [b]
map_send_to x = map (send_to(x))

belongs_to :: (Foldable t, Eq a) => t a -> a -> Bool
belongs_to = flip elem

has :: (Foldable t, Eq b) => b -> t b -> Bool
has = flip belongs_to

indexed :: (Num t, Enum t) => [b] -> [(t, b)]
indexed = zip([0..])

map_with_index :: (Num t, Enum t) => ((t, b) -> b1) -> [b] -> [b1]
map_with_index f = indexed > map f

ljust, rjust :: Int -> a -> [a] -> [a]
rjust n x xs 
  | n P.< xs.length = xs
  | otherwise     = ( n.times x ++ xs ).reverse.take n.reverse

ljust n x xs
  | n P.< xs.length = xs
  | otherwise     = ( xs ++ n.times x ).take n


powerslice :: [a] -> [[a]]
powerslice xs = [ xs.slice j (j+i) |
  i <- l.downto 1,
  j <- [0..l <-> i]
  ]
  where l = xs.length

-- only works for sorted list
-- but could be infinite 
-- e.g. a `common` b `common` c
common :: (Ord a) => [a] -> [a] -> [a]
common _ []   = []
common [] _   = []
common a@(x:xs) b@(y:ys)
  | x .is y   = y : common xs b
  | x P.< y     = common xs b
  | otherwise = common a ys


-- faster reverse sort
rsort :: (Ord a) => [a] -> [a]
rsort xs = xs.L.sortBy(\a b -> b `compare` a)

encode :: (Eq a) => [a] -> [(Int, a)]
encode xs = xs.L.group.map (length &&& head)

decode :: [(Int, a)] -> [a]
decode xs = xs.map(\(l,x) -> l.times x).join'


only_one :: [a] -> Bool
only_one [_]    = True
only_one _      = False

concat_map :: (a -> [b]) -> [a] -> [b]
concat_map = concatMap

-- Fold
to_list :: (Foldable t) => t a -> [a]
to_list = toList

-- Set
to_set :: (Ord a) => [a] -> S.Set a
to_set = S.fromList

-- Map
to_h :: (Ord k) => [(k, a)] -> M.Map k a
to_h xs = xs.M.fromList

-- Array
to_a :: [a] -> A.Array Int a
to_a xs      = A.listArray (0, xs.length <-> 1) xs

to_a' :: (A.Ix i) => (i, i) -> [e] -> A.Array i e
to_a' i xs = A.listArray i xs

hist :: (Num e, A.Ix i) =>  (i, i) -> [i] -> A.Array i e
hist bnds ns = A.accumArray (+) 0 bnds [(n, 1) | n <- ns, A.inRange bnds n]

-- Ord
compare_by :: (Ord b) => (a -> b) -> a -> a -> Ordering
compare_by = on compare

eq, is, is_not, isn't, aren't :: (Eq a) => a -> a -> Bool
eq         = flip (==)
is         = eq
is_not a b = not (is a b)
isn't      = is_not
aren't     = is_not

-- Tuple
swap :: (a, b) -> (b, a)
swap (x,y) = (y,x)

tuple2 :: (Show a) => [a] -> (a, a)
tuple2 = first &&& last

tuple3 :: (Show a) => [a] -> (a, a, a)
tuple3 xs = (xs.first, xs.second, xs.third)

list2 :: (a, a) -> [a]
list2 (x,y) = [x,y]

list3 :: (a, a, a) -> [a]
list3 (x,y,z) = [x,y,z]

filter_fst :: (a -> Bool) -> [(a, b)] -> [(a, b)]
filter_fst f = filter(fst > f)

filter_snd :: (b -> Bool) -> [(a, b)] -> [(a, b)]
filter_snd f = filter(snd > f)

only_fst :: [(a, b)] -> [a]
only_fst = map fst

only_snd :: [(a, b)] -> [b]
only_snd = map snd

map_fst :: (a -> b) -> [(a, c)] -> [(b, c)]
map_fst f = map(\(a,b) -> (f a, b))

map_snd :: (a -> b) -> [(c, a)] -> [(c, b)]
map_snd f = map(\(a,b) -> (a, f b))

pair :: ((a, b) -> c) -> a -> b -> c
pair f a b = f (a,b) 

triple :: ((a, b, c) -> d) -> a -> b -> c -> d
triple f a b c = f (a,b,c)

splat :: (a -> b -> c) -> (a, b) -> c
splat f (a,b) = f a b

splat3 :: (a -> b -> c -> d) -> (a, b, c) -> d
splat3 f (a,b,c) = f a b c

twin :: a -> (a, a)
twin x = (x,x)

-- Integer
from_i :: (Integral a, Num b) => a -> b
from_i = fromIntegral

explode :: (Show a) => a -> [Int]
explode n = n.show.map digitToInt

-- String
lower, upper :: String -> String
lower = map toLower
upper = map toUpper

starts_with, ends_with :: String -> String -> Bool
starts_with = L.isPrefixOf
ends_with   = L.isSuffixOf

capitalize :: String -> String
capitalize [] = []
capitalize (x:xs) = [x].upper ++ xs.lower

to_s :: (Show a) => a -> String
to_s = show


-- Debug
trace' :: (Show a) => a -> a
trace' x = trace (x.show) x



-- New from Lab
at :: (Show a) => Int -> [a] -> a
at i xs = if i P.< xs.length
  then xs !! i
  else error - show xs ++ " at " ++ show i ++ " failed"

void :: (Monad m) => m a -> m ()
void x = x >>= const () > return

don't :: (Monad m) => m a -> m ()
don't = const - return ()

length :: (Num i) => [a] -> i
length = genericLength

drop :: (Integral i) => i -> [a] -> [a]
drop = genericDrop

to_f :: (Real a, Fractional b) => a -> b
to_f = realToFrac 

sleep :: (RealFrac a) => a -> IO ()
sleep x = threadDelay - round - (x * 1000000)

first_or :: a -> [a] -> a
first_or x xs = case xs of
  [] -> x
  (y:_) -> y

puts :: String -> IO ()
puts = putStrLn


exit_success :: IO ()
exit_success = exitWith ExitSuccess

fork :: IO a -> IO ()
fork io = void - forkIO - void io

insert_unique :: (Eq a) => a -> [a] -> [a]
insert_unique x xs = x : xs.reject (is x)

squeeze :: (Monad m) => m (m a) -> m a
squeeze = Monad.join

end :: (Monad m) => m ()
end = return ()