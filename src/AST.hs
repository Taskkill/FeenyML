module AST where

import qualified Tokens as Token 

data AST
  = Number Int
  | Boolean Bool
  | Unit
  | Block [AST]
  | FunctionDef String [String] AST
  | Let String AST
  | OperatorDef Operator [String] AST
  | ObjectDef AST [AST]
  | ReAssignment String AST
  | FieldReAssignment AST AST
  | ArrayIndexReAssignment AST AST
  | Identifier String
  | If AST AST AST
  | While AST AST
  | ObjectFieldAccess AST [AST] String
  | Method AST [AST] AST
  | ArrayDef AST AST
  | Application AST [AST]
  | ArrayAccess AST AST
  | Print String [AST]
  | Operation Operator AST AST
  deriving (Eq, Show)

data Operator
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
  deriving (Eq, Show)