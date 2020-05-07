module VM.Memory where

import qualified Data.Map.Strict as Map

import VM.Value (Value)


-- REFACTOR: Use List instead of Map
-- 
type Memory = (Int, Map.Map Int Value)
