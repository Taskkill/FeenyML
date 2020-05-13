module VM.Program where

import VM.Program.Instruction (Instruction(..))
import VM.Program.Value (Index, Value(..))
import qualified Data.Map.Strict as Map
import VM.Value (Pointer(..))

type Inst = (Instruction, Index)

-- type Globals = [Int]

data Program = P
  { left    :: [Inst]
  , el      :: Inst
  , right   :: [Inst] }

type GlobalVarMap = Map.Map String Pointer
type SubprogramDir = Map.Map String Index
type ConstPool = Map.Map Index Value
type Globals = [Index]
type FunctionList = [Value] -- only Function


data PProgram = PP
  { program   :: Program -- Zipper
  , labels    :: SubprogramDir -- Program
  , constpool :: ConstPool -- Program
  , globals   :: Globals -- GlobalSlots?? then Program
  , fns       :: FunctionList } -- Program


-- TODO: add ConstantPool, GlobalSlots, MainFunction
-- I shoudln't really add them here - let's just make another helper structure which will hold these values

instructions2Program :: [Instruction] -> Program
instructions2Program (i : is) = P { left = [], el = (i, 0), right = toInsts is 1 }
  where
    toInsts :: [Instruction] -> Int -> [Inst]
    toInsts [] _ = []
    toInsts (i : is) n = (i, n) : (toInsts is $ n + 1)

moveRight :: Program -> Program
moveRight P { left = l, el = e, right = r : rs } =
  P { left = e : l, el = r, right = rs }

moveLeft :: Program -> Program
moveLeft P { left = l : ls, el = e, right = r } =
  P { left = ls, el = l, right = e : r }

setToInstruction :: Index -> Program -> Program
setToInstruction addr p@P { left = l, el = (inst, instAddr), right = r }
  | addr == instAddr = p
  | addr > instAddr = setToInstruction addr $ moveRight p
  | addr < instAddr = setToInstruction addr $ moveLeft p
