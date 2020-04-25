module VM.State where

import qualified Data.Sequence as Seq
import qualified Data.Map.Strict as Map
import VM.Data.Value (Value(..), Operand(..), Index, RuntimeValue)
import VM.Stack
import VM.Data.Frame (Frame(..))
import VM.Data.Memory
import VM.Data.Program
import VM.Data.Instruction

type Context = [Frame]

type GlobalVarMap = Map.Map String Operand

type SubprogramDir = Map.Map String InstructionAddress

type OperandStack = Stack Operand

type Output = Seq.Seq String

type ConstPool = Map.Map Index Value

-- data Context
--   = Global Frame
--   | Local Frame Context

data State
  = CS { c      :: Context
       , g      :: GlobalVarMap
       , p      :: SubprogramDir
       , s      :: OperandStack
       , o      :: Output
       , cp     :: ConstPool
       , ia     :: InstructionAddress
       , m      :: Memory }
