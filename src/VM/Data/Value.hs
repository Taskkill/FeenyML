module VM.Data.Value where


data Value
  = Null
  | Int Int
  | String String
  | Slot -- here goes something
  | Function --


data Operand
  = Null
  | Int Int
  | Array [Operand] -- I am not sure Operand is the right type