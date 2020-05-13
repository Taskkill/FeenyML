module VM.Frame where

-- import VM.Data.Memory (Memory)
import VM.Program.Value (Value(..), Index)
import VM.Value (Pointer(..))

data Frame = Frame
  { arguments :: [Pointer] -- really? are those Runtime.Values?
  , variables :: [Pointer] -- really? are those Runtime.Values?
  , caller    :: Index }