module VM.Data.Frame where

import VM.State (Memory)

type InstructionAddress = Int

data Frame =
  Frame { arguments :: [(String, Operand)]
        , variables :: [(String, Operand)]
        , caller    :: InstructionAddress
        , parent    :: Frame }