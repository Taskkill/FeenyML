module VM.State where

import qualified Data.Sequence as Seq
import qualified Data.Map.Strict as Map

import VM.Program.Value (Value(..), Index)
import qualified VM.Value as Runtime
import VM.Lib.Stack
import VM.Frame (Frame(..))
import VM.Memory
import VM.Program
import VM.Program.Instruction

type Context = [Frame]

type GlobalVarMap = Map.Map String Runtime.Value

type SubprogramDir = Map.Map String InstructionAddress

type OperandStack = Stack Runtime.Value

type Output = Seq.Seq String

type ConstPool = Map.Map Index Value

type FunctionList = [Value] -- only Function

data State
  = CS { c      :: Context
       , g      :: GlobalVarMap
       , p      :: SubprogramDir
       , s      :: OperandStack
       , o      :: Output
       , cp     :: ConstPool
       , ia     :: InstructionAddress
       , m      :: Memory
       , gs     :: Globals
       , fns    :: FunctionList }
