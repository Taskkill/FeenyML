module VM.Data.Program where

data Program a
  = { left :: [a]
    , elem :: a
    , right :: [a]
    }