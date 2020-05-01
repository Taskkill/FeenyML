module VM.Program where

import VM.Program.Instruction (Instruction(..))
import VM.Program.Value (Index)

type Inst = (Instruction, InstructionAddress)

type InstructionAddress = Index

type Globals = [Int]

data Program = P
  { left    :: [Inst]
  , el      :: Inst
  , right   :: [Inst] }

-- TODO: add ConstantPool, GlobalSlots, MainFunction

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

setToInstruction :: InstructionAddress -> Program -> Program
setToInstruction addr p@P { left = l, el = (inst, instAddr), right = r }
  | addr == instAddr = p
  | addr > instAddr = setToInstruction addr $ moveRight p
  | addr < instAddr = setToInstruction addr $ moveLeft p
