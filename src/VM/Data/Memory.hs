module VM.Data.Memory where

import qualified Data.Map.Strict as Map

import VM.Data.Value (Operand(..))

type Memory = (Int, Map.Map Int Operand)
