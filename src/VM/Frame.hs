module VM.Frame where

-- import VM.Data.Memory (Memory)
import VM.Program.Value (Value(..))
import qualified VM.Value as Runtime
import VM.Program (InstructionAddress)

data Frame = Frame
  { arguments :: [Runtime.Value] -- really? are those Runtime.Values?
  , variables :: [Runtime.Value] -- really? are those Runtime.Values?
  , caller    :: InstructionAddress }