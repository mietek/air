{-# LANGUAGE TemplateHaskell #-}

module Air.TH.Default where

import Language.Haskell.TH
import Air.Data.Default


-- $(reify ''Dummy >>= show > stringE)
-- "TyConI (DataD [] Main.Dummy [] [RecC Main.Dummy [(Main.test_field_1,NotStrict,ConT GHC.Base.String),(Main.test_field_2,NotStrict,ConT GHC.Integer.Type.Integer)]] [])"

-- runQ [d| instance Default Dummy where def = Dummy def def |]
-- [InstanceD [] (AppT (ConT Data.Default.Default) (ConT Main.Dummy)) [ValD (VarP def) (NormalB (AppE (AppE (ConE Main.Dummy) (VarE def)) (VarE def))) []]]

-- runQ [d| instance Default Dummy where def = Dummy {test_field_1 = def, test_field_2 = def} |]
-- [InstanceD [] (AppT (ConT Data.Default.Default) (ConT Main.Dummy)) [ValD (VarP def) (NormalB (RecConE Main.Dummy [(Main.test_field_1,VarE def),(Main.test_field_2,VarE def)])) []]]

-- Example:

-- data Dummy = Dummy
--   {
--     test_field_1 :: String
--   , test_field_2 :: Integer
--   }
--   deriving (Show)
-- 
-- mkDefault ''Dummy
-- 
-- gives:

-- instance Default Dummy where
--     { def = Dummy {test_field_1 = def, test_field_2 = def} }


mkDefault :: Name -> Q [Dec]
mkDefault name = do
  info <- reify name
  case info of
    TyConI x -> do
      case x of
        (DataD _ data_name _ recs _)  -> do
          case recs of
            [] -> error $ "no phantom type"
            (RecC record_name fields):_ -> do
              let def_name = mkName "def"
              let def_fields = map (\(field_name, _, _) -> (field_name, VarE def_name)) fields
              return $ return $ 
                InstanceD [] 
                  (AppT (ConT ''Default) (ConT data_name)) 
                  [ValD (VarP def_name) (NormalB (RecConE record_name def_fields)) []]
        NewtypeD _ _ _ _ _ -> error "Newtypes are not supported"
        _ -> error $ "Unknown declaration type"
    _        -> error "Only datatypes can be processed"