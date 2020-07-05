{
module Scanner where

import Tokens (Token(..))
}

%wrapper "basic"

$digit = 0-9
$alpha = [a-zA-Z]

tokens :- 

  $white+                                 ;
  (\/\*([^\)][^\*][\s]*)*\*\\)            ;
  \(                                      { \s -> LeftParen }
  \)                                      { \s -> RightParen }
  \[                                      { \s -> LeftBracket }
  \]                                      { \s -> RightBracket }
  \;                                      { \s -> Semicolon }
  \,                                      { \s -> Comma }
  \.                                      { \s -> Dot }
  \=                                      { \s -> Be }
  \-\>                                    { \s -> RightArrow }
  \<\-                                    { \s -> LeftArrow }

  \+                                      { \s -> Plus }
  \-                                      { \s -> Minus }
  \*                                      { \s -> Multiply }
  \/                                      { \s -> Divide }
  \%                                      { \s -> Modulo }
  \<\=                                    { \s -> LesserEqual }
  \>\=                                    { \s -> GreaterEqual }
  \<                                      { \s -> Lesser }
  \>                                      { \s -> Greater }
  \|                                      { \s -> Or }
  \&                                      { \s -> And }
  \=\=                                    { \s -> Equal }
  \!\=                                    { \s -> UnEqual }

  while                                   { \s -> While }
  object                                  { \s -> Object }
  if                                      { \s -> If }
  else                                    { \s -> Else }
  then                                    { \s -> Then }
  true                                    { \s -> T }
  false                                   { \s -> F }
  array                                   { \s -> Array }
  unit                                    { \s -> Unit }
  let                                     { \s -> Let }
  begin                                   { \s -> Begin }
  end                                     { \s -> End }
  this                                    { \s -> This }
  print                                   { \s -> Print }
  function                                { \s -> Function }
  do                                      { \s -> Do }
  extends                                 { \s -> Extends }

  [_$alpha]([$alpha$digit]|_\')*          { \s -> Identifier s -- [this[_$alpha][$alpha$digit]*] }
  \-?$digit+                              { \s -> Number $ read s }
  "$alpha"                                { \s -> String $ read s -- fix }

{
scan = alexScanTokens
}