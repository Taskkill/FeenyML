module VM.State where

import qualified Data.Sequence as Seq
import qualified Data.Map.Strict as Map

import VM.Program.Value (Value(..), Index)
import VM.Value (Pointer)
import qualified VM.Value as Runtime
import VM.Lib.Stack
import VM.Frame (Frame(..))
import VM.Memory
import VM.Program
import VM.Program.Instruction

type Context = [Frame]

type GlobalVarMap = Map.Map String Pointer

type SubprogramDir = Map.Map String InstructionAddress

type OperandStack = Stack Pointer

type Output = Seq.Seq String

type ConstPool = Map.Map Index Value

type FunctionList = [Value] -- only Function

-- TODO: consider finally dividing Immutable and Program related stuff to different Structure
-- State should be only VM realted State stuff
data State = CS
  { ctx       :: Context -- VM State
  , gvm       :: GlobalVarMap -- Program
  , labels    :: SubprogramDir -- Program
  , stack     :: OperandStack -- VM State
  , out       :: Output -- VM State
  , constpool :: ConstPool -- Program
  , instaddr  :: InstructionAddress -- VM Program
  , memory    :: Memory -- VM Program
  , globals   :: Globals -- 
  , fns       :: FunctionList } -- Program
