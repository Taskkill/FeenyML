module VM.Data.Frame where

-- import VM.Data.Memory (Memory)
import VM.Data.Value (Operand(..))
import VM.Data.Program

data Frame = Frame
  { arguments :: [(String, Operand)]
  , variables :: [(String, Operand)]
  , caller    :: InstructionAddress
  , parent    :: Frame }