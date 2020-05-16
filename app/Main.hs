module Main where

import qualified Data.List as List

import Tokens (Token(..))
import Scanner (scan)
import Parser (parse)
import Interpreter (evaluate)

-- import VM.Interpreter
-- import Compiler.Desugarizer (blocksToLambdas, localFnsToGlobal)

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
  -- let desugarized = localFnsToGlobal $ blocksToLambdas $ ast
  -- r <- evaluate ast
  -- case r of
  --   Left msg -> print msg
  --   Right v -> print v
  -- print ".............................................."
  -- putStrLn $ List.intercalate ";\n" $ List.map show ast
  -- print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  -- putStrLn $ List.intercalate ";\n" $ List.map show desugarized
  -- print "______________________________________________"
