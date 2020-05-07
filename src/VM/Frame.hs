module VM.Frame where

-- import VM.Data.Memory (Memory)
import VM.Program.Value (Value(..))
import VM.Value (Pointer(..))
import VM.Program (InstructionAddress)

data Frame = Frame
  { arguments :: [Pointer] -- really? are those Runtime.Values?
  , variables :: [Pointer] -- really? are those Runtime.Values?
  , caller    :: InstructionAddress }