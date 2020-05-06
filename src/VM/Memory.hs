module VM.Memory where

import qualified Data.Map.Strict as Map

import qualified VM.Value (Value)

type Memory = (Int, Map.Map Int Value)
