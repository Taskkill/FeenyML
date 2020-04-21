module VM.Data.Program where

import VM.Data.Instruction (Instruction(..))
import VM.Data.Frame

type Inst = (Instruction, InstructionAddress)

data Program
  = P { left :: [Inst]
    , elem :: Inst
    , right :: [Inst]
    }