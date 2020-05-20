module VM.Value where

import qualified VM.Program.Value as Program

type Address = Int

-- use GADT
-- Pointer is distinct type which only goes on the Stack
-- Value --> Memory
-- All Values go to the memory
-- Array, Object contain Pointers

data Value
  = Int Int
  | Null
  | Array { vals :: [Pointer] }
  | Object { vars :: [Pointer], super :: Pointer, cl :: Program.Value }
  | AntiValue
  deriving (Show)

data Pointer = Pointer Address
              deriving (Show)

-- data Value
--   = Int Int
--   | Null
--   | Pointer Address
--   | Array { vals :: [Value] } -- really Runtime.Value ? I think so
--   | Object { vars :: [Value], super :: Value, cl :: Program.Value } -- Value here is Class  -- vars -> really Runtime.Value ?
--   -- | AntiValue -- just in case I decide to use it -> to initialize locals, globals and stuff
