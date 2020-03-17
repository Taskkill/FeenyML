module Tokens where

data Token
  = LeftParen
  | RightParen
  | LeftBracket
  | RightBracket
  | Semicolon
  | Dot
  | Comma
  | Be
  | RightArrow
  | LeftArrow
  | Plus
  | Minus
  | Multiply
  | Divide
  | Modulo
  | LesserEqual
  | GreaterEqual
  | Lesser
  | Greater
  | Or
  | And
  | Equal
  | UnEqual
  | While
  | Object
  | If
  | Else
  | Then
  | T
  | F
  | Array
  | Unit
  | Let
  | Begin
  | End
  | This
  | Print
  | Function
  | Do
  | Extends
  | Identifier String
  | Number Int
  | String String
  deriving (Eq, Show)