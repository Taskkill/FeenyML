module VM.Data.Value where

import VM.Data.Instruction (Instruction(..))


type Index = Int

-- Program Objects
data Value
  = Null -- Null or Unit value in FeenyML
  | Int Int -- 32 bit integer or whatever
  | String String -- names of functions, methods, slots, labels
  | Slot Index -- index refering to the String object, either object variable when used in class or global variable
  | Function Index Int Int [Instruction] -- global function (local too) or class method -- index to the name, number of arguments, number of local variables, body
  | Class [Index] -- index points to either Function or Slot

type Address = Int

-- 
data Operand
  = OInt Int
  | ONull
  | Pointer Address

data RuntimeValue
  = RNull
  | RInt Int
  | Array { vals :: [RuntimeValue] }
  | Object { vars :: [RuntimeValue], super :: RuntimeValue, cl :: Value } -- Value here is Class 