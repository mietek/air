-- {-# LANGUAGE CPP #-}

module Air.Here.TH where

import Language.Haskell.TH.Quote 
import Language.Haskell.TH.Syntax 
import Language.Haskell.TH.Lib 


here :: QuasiQuoter 
here = 
  QuasiQuoter 
    {
      quoteExp = litE . stringL
    , quotePat = litP . stringL
    }
