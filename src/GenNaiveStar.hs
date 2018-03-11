module GenNaiveStar where

import GRegexp
import Data.List hiding (intersect)
import qualified Data.List (intersect)

import LLeq
import OrderedLists
import Partitions

type Segments t = [Lang t]

-- for infinite lists of segments
mergeSegs :: (Ord t) => Segments t -> Segments t -> Segments t
mergeSegs = zipWith merge

intersectSegs :: (Ord t) => Segments t -> Segments t -> Segments t
intersectSegs = zipWith intersect

differenceSegs :: (Ord t) => Segments t -> Segments t -> Segments t
differenceSegs = zipWith difference

multimerge :: (Ord t) => [Lang t] -> Lang t
multimerge = foldr merge []

sigmaStarSegs :: [t] -> Segments t
sigmaStarSegs sigma = segments
  where
    segments = [[]] : map extend segments
    extend segment = concatMap (\x -> map (x:) segment) sigma

concatenate :: (Ord t) => Segments t -> Segments t -> Segments t
concatenate xsegs ysegs = collect 0
  where
    collect n =
      let combine i = concatMap (\xs -> map ( xs ++ ) (ysegs !! (n - i))) (xsegs !! i)
      in  (multimerge $ map combine [0 .. n]) : collect (n+1)

-- the star operation

-- | computing the indexesOfNonEmptysegs by accumulation
star :: (Ord t) => Segments t -> Segments t
star xsegs = rsegs
  where
    rsegs = [[]] : collect 1
    collect n = 
      let combine i = concatMap (\xs -> map (xs++) (rsegs !! (n - i))) (xsegs !! i)
      in  (multimerge $ map combine [1 .. n]) : collect (n + 1)

complementSegs :: (Ord t) => [t] -> Segments t -> Segments t
complementSegs sigma = differenceSegs (sigmaStarSegs sigma)

-- | generate elements of the language of the gre as a stream of segments
generate' :: (Ord t) => [t] -> GRE t -> Segments t
generate' sigma r = gen r
  where
    gen Zero = repeat []
    gen One  = [[]] : repeat []
    gen (Atom t) = [] : [[t]] : repeat []
    gen (Dot r s) = concatenate (gen r) (gen s)
    gen (Or r s) = mergeSegs (gen r) (gen s)
    gen (And r s) = intersectSegs (gen r) (gen s)
    gen (Not r) = complementSegs sigma (gen r)
    gen (Star r) = star (gen r)

generate :: (Ord t) => [t] -> GRE t -> Lang t
generate sigma = concat . generate' sigma

