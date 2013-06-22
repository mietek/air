{-# LANGUAGE TemplateHaskell #-}


import Language.Haskell.TH
import Air.Env
import Air.TH
import Prelude ()
import Air.Data.Default
import System.Nemesis.Titan

data Dummy = Dummy
  {
    test_field_1 :: String
  , test_field_2 :: Integer
  }
  deriving (Show)

mkDefault ''Dummy

main = 
  halt

