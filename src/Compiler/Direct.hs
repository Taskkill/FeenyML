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
    Number i -> undefined
    Boolean b -> undefined
    Unit -> undefined

    FunctionDef _ _ _ -> program

    Block exprs -> undefined

    Let n v -> undefined

    ObjectDef _ _ -> undefined

    ReAssignment name value -> undefined

    FieldReAssignment accessor value -> undefined

    ArrayIndexReAssignment accessor value -> undefined

    Identifier name -> undefined

    If condition then' else' -> undefined

    While cond do' -> undefined

    ObjectFieldAccess obj [] -> undefined

    ObjectFieldAccess obj (a:as) -> undefined

    ArrayDef _ _ -> undefined

    Application (Identifier fname) args -> undefined

    Application (ObjectFieldAccess obj accessors) args -> undefined

    ArrayAccess accessible member -> undefined

    Print format args -> undefined

    Operation op left right -> undefined
