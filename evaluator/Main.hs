module Main where

import qualified Data.List as List

import Tokens (Token(..))
import Scanner (scan)
import Parser (parse)
import Interpreter (evaluate)

-- import VM.Interpreter
import Compiler.Desugarizer (desugarize, blocksToLambdas, localFnsToGlobal)
import Compiler.Translator (translate)
import VM.Program (Program(..))
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq

import VM.Frame
import VM.State
import qualified VM.Lib.Stack as Stack
import VM.Interpreter (runProgram)
import VM.Program (setToInstruction)

-- import Lib

main :: IO ()
main = do
  i <- getContents
  let tokens = scan i
  let ast = parse tokens
  r <- evaluate ast
  print "AST Interpreter Evaluated the Program to:"
  case r of
    Left msg -> print msg
    Right v -> print v