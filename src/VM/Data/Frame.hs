module VM.Data.Frame where


data Frame =
  Frame { arguments :: [Value]
        , variables :: [Value]
        , caller    :: InstructionAddress
        , parent    :: Frame } 