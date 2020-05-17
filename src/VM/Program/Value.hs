module VM.Program.Value where

import VM.Program.Instruction (Instruction(..))


type Index = Int

-- Program Objects
data Value
  = Null -- Null or Unit value in FeenyML
  | Int Int -- 32 bit integer or whatever
  | Bool Bool -- Boolean value
  | String String -- names of functions, methods, slots, labels
  | Slot Index -- index refering to the String object, either object variable when used in class or global variable
  | Function { nameInd :: Index, argsCnt :: Int, varsCnt :: Int, body :: [Instruction] } -- global function (local too) or class method -- index to the name, number of arguments, number of local variables, body
  | Class [Index] -- index points to either Function or Slot
  deriving (Eq, Ord, Show)