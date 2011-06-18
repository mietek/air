{-# LANGUAGE TemplateHaskell #-}

module Air.TH.Air where

import Language.Haskell.TH
import Control.Monad (replicateM)


{-
> $(tuple 3) [1,2,3,4,5]
 (1,2,3)
 > $(tuple 2) [1,2]
 (1,2)
-}
tuple :: Int -> ExpQ
tuple n = do
    ns <- replicateM n (newName "x")
    lamE [foldr (\x y -> conP '(:) [varP x,y]) wildP ns] (tupE $ map varE ns)
