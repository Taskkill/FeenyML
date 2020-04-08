module VM.State where

import qualified Data.Map.Strict as Map
import VM.Data.Value (Value(..), Operand(..))
import VM.Stack

type GlobalVarMap = Map String Value

type OperandStack = Stack Operand