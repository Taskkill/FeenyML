module VM.Value where

import qualified VM.Program.Value as Program

type Address = Int

-- 
-- TODO: CHANGE THIS
-- INSTEAD OF OPERAND - VMOBJECT
-- IT CAN BE INT, NULL, POINTER
-- DELETE RUNTIMEVALUE RINT, RNULL
-- RENAME RUNTIMEVALUE TO SOMETHING DESCRIPTIVE - LIKE OBJECT OR SOMETHING
-- LET'S SAY: DONE
data Value
  = Int Int
  | Null
  | Pointer Address
  | Array { vals :: [Value] } -- really Runtime.Value ? I think so
  | Object { vars :: [Value], super :: Value, cl :: Program.Value } -- Value here is Class  -- vars -> really Runtime.Value ?
  | AntiValue -- just in case I decide to use it -> to initialize locals, globals and stuff
