module Compiler.Direct.Translator where

import AST (AST, Operator)
import VM.Program.Instruction (Instruction)


translate :: [AST] -> Program
translate ast =
  -- do stuff
  -- register all global functions
  -- local functions are gonna be translated to jumps
  -- then translate all AST Node into corresponding Program Instruction


translate' :: AST -> Program -> Program
translate' ast program =
  case ast of
    Number i -> undefined --

    Boolean b -> undefined --
    
    Unit -> undefined --

    FunctionDef _ _ _ -> program -- already taken care of

    Block exprs -> undefined
    -- consider two options
    -- A) treating Blocks as functions -- this will only work if local functions are implemented as real fucntions
    -- B) treating Blocks as jumps
    -- essentially I am going to implement Blocks as the local functions
    -- whichever impl will be chosen for loc. fns will also be chosen for the blocks

    Let n v -> undefined
    -- SetLocal or SetGlobal -- in both cases - when entering Context/Frame - variable is already declared

    ObjectDef _ _ -> undefined
    -- Object

    ReAssignment name value -> undefined
    -- SetLocal or SetGlobal

    FieldReAssignment accessor value -> undefined
    -- SetSlot

    ArrayIndexReAssignment accessor value -> undefined
    -- SetSlot

    Identifier name -> undefined --

    If condition then' else' -> undefined
    -- Branch

    While cond do' -> undefined
    -- Branch

    ObjectFieldAccess obj [] -> undefined
    -- GetSlot

    ObjectFieldAccess obj (a:as) -> undefined
    -- GetSlot -- chain of them

    ArrayDef _ _ -> undefined
    -- Array

    Application (Identifier fname) args -> undefined
    -- Call

    Application (ObjectFieldAccess obj accessors) args -> undefined
    -- resolve the whole accessor chain - then call the last one as method - chain of GetSlots
    -- CallSlot

    ArrayAccess accessible member -> undefined
    -- GetSlot

    Print format args -> undefined
    -- Print

    Operation op left right -> undefined
    -- CallSlot
