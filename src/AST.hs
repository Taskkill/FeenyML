module AST where

import qualified Data.List as List

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
  | ObjectFieldAccess AST [String]
  | Method AST [AST] AST -- TODO: probably unused --> remove
  | ArrayDef AST AST
  | Application AST [AST]
  | ArrayAccess AST AST
  | Print String [AST]
  | Operation Operator AST AST
  | This
  deriving (Eq)

instance Show AST where
  show (Number i) = show i
  show (Boolean True) = "true"
  show (Boolean False) = "false"
  show Unit = "begin end"
  show (Block exprs) = "begin\n" ++ (List.intercalate "\n" (List.map show exprs)) ++ "\nend"
  show (FunctionDef name params body) = "function " ++ name ++ " (" ++ (List.intercalate "," params) ++ ") ->\n" ++ show body
  show (Let name expr) = "let " ++ name ++ " = " ++ show expr
  show (OperatorDef op params body) = "operator " ++ show op ++ " (" ++ (List.intercalate "," params) ++ ") ->\n" ++ show body
  show (ObjectDef super definition) = "[object]"
  show (ReAssignment name expr) = name ++ " <- " ++ show expr
  show (FieldReAssignment object expr) = show object ++ " <- " ++ show expr
  show (ArrayIndexReAssignment array value) = show array ++ " <- " ++ show value
  show (Identifier name) = name
  show (If cond then' else') = "if " ++ show cond ++ " then\n" ++ show then' ++ "\nelse\n" ++ show else'
  show (While cond body) = "while " ++ show cond ++ " do\n" ++ show body
  show (ObjectFieldAccess object members) = show object ++ "." ++ List.intercalate "." members
  show (Method _ _ _) = "[method]"
  show (ArrayDef len init) = "Array(" ++ show len ++ ", " ++ show init ++ ")"
  show (Application fn args) = show fn ++ "(" ++ List.intercalate "," (List.map show args) ++ ")"
  show (ArrayAccess array index) = show array ++ "[" ++ show index ++ "]"
  show (Print format args) = "Print(" ++ format ++ ", " ++ (List.intercalate "," $ List.map show args) ++ ")"
  show (Operation op left right) = show left ++ " " ++ show op ++ " " ++ show right
  show This = "this"


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
  deriving (Eq)

instance Show Operator where
  show Multiply = "*"
  show Plus = "+"
  show Minus = "-"
  show Divide = "/"
  show Modulo = "%"
  show UnEqual = "!="
  show Equal = "=="
  show Lesser = "<"
  show Greater = ">"
  show LesserEqual = "<="
  show GreaterEqual = ">="
  show And = "&"
  show Or = "|"
