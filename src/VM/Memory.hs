module VM.Memory where

import qualified Data.Map.Strict as Map

import qualified VM.Value as Runtime

type Memory = (Int, Map.Map Int Runtime.Value)
