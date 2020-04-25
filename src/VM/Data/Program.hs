module VM.Data.Program where

import VM.Data.Instruction (Instruction(..))

type Inst = (Instruction, InstructionAddress)

type InstructionAddress = Int

data Program = P
  { left  :: [Inst]
  , el      :: Inst
  , right   :: [Inst] }

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
