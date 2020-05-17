module Main where

import qualified Data.List as List

import Tokens (Token(..))
import Scanner (scan)
import Parser (parse)
import Interpreter (evaluate)

-- import VM.Interpreter
import Compiler.Desugarizer (desugarize)
import Compiler.Translator (translate)
import VM.Program (Program(..))
import qualified Data.Map.Strict as Map

-- import Lib

main :: IO ()
main = do
  i <- getContents
  let tokens = scan i
  let ast = parse tokens
  r <- evaluate ast
  case r of
    Left msg -> print msg
    Right v -> print v
  print "----------------------------------------------"
  -----------------------------------------------------
  let desugarized = desugarize ast
  r <- evaluate desugarized
  case r of
    Left msg -> print msg
    Right v -> print v
  print ".............................................."
  putStrLn $ List.intercalate ";\n" $ List.map show ast
  print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  putStrLn $ List.intercalate ";\n" $ List.map show desugarized
  print "______________________________________________"
  ------------------------
  let (prg, zipper, insts) = translate ast
  print prg
  print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  -- print $ right zipper
  print insts