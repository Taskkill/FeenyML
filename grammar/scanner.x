{
  module Main where
}

%wrapper "basic"

$digit = 0-9
$alpha = [a-zA-Z]

tokens :- 

  $white+                         ;
  \(\*([^\)][^\*])*\)\*           ;
  \(                              { \s -> LeftParen }
  \)                              { \s -> RightParen }
  \[                              { \s -> LeftBracket }
  \]                              { \s -> RightBracket }
  \;                              { \s -> Semicolon }
  \.                              { \s -> Dot }
  \=                              { \s -> Be }
  \-\>                            { \s -> RightArrow }
  \<\-                            { \s -> LeftArrow }

  \+                              { \s -> Plus }
  \-                              { \s -> Minus }
  \*                              { \s -> Multiply }
  \/                              { \s -> Divide }
  \%                              { \s -> Modulo }
  \<\=                            { \s -> LesserEqual }
  \>\=                            { \s -> GreaterEqual }
  \<                              { \s -> Lesser }
  \>                              { \s -> Greater }
  \|                              { \s -> Or }
  \&                              { \s -> And }
  \=\=                            { \s -> Equal }
  \!\=                            { \s -> UnEqual }

  while                           { \s -> While }
  object                          { \s -> Object }
  if                              { \s -> If }
  else                            { \s -> Else }
  then                            { \s -> Then }
  true                            { \s -> T }
  false                           { \s -> F }
  array                           { \s -> Array }
  unit                            { \s -> Unit }
  let                             { \s -> Let }
  begin                           { \s -> Begin }
  end                             { \s -> End }
  this                            { \s -> This }
  print                           { \s -> Print }
  function                        { \s -> Function }
  do                              { \s -> Do }
  extends                         { \s -> Extends }

  this|[_$alpha]([$alpha$digit]|_\')* { \s -> Identifier s -- [this[_$alpha][$alpha$digit]*] }
  \-?$digit+                      { \s -> Number $ read s }
  "$alpha"                        { \s -> String $ read s -- fix }

{
data Token
  = LeftParen
  | RightParen
  | LeftBracket
  | RightBracket
  | Semicolon
  | Dot
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
  deriving (Eq,Show)

main = do
  s <- getContents
  print (alexScanTokens s)

}