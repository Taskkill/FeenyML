module AST where

import qualified Tokens as Token 

data AST
  = Multiply
  | Plus
  | Minus
  | Divide
  | Modulo
  | UnEqual
  | Equal
  | Lesser
  | Greater
  | LesserEqual
  | GreaterEqual
  | And
  | Or
  | Number Int
  | Boolean Bool
  | Unit
  | Block [AST]
  | FunctionDef String [AST] AST
  | Let String AST
  | OperatorDef AST [AST] AST
  | Extends AST
  | ObjectDef AST [AST] [AST]
  | ReAssignment String AST
  | FieldReAssignment AST AST
  | ArrayIndexReAssignment AST AST
  | Identifier String
  | If AST AST AST
  -- | Null
  | While AST AST
  | ObjectFieldAccess AST [AST] String
  | Method AST [AST] AST
  | Array
  | ArrayDef AST AST
  | Application AST [AST]
  | ArrayAccess AST AST
  | Print String [AST]
  | Operation AST AST AST
  deriving (Eq, Show)