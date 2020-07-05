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
  -- r <- evaluate ast
  -- case r of
  --   Left msg -> print msg
  --   Right v -> print v
  -- print "----------------------------------------------"
  -----------------------------------------------------
  let desugarized = desugarize ast
  -- r <- evaluate desugarized
  -- case r of
  --   Left msg -> print msg
  --   Right v -> print v
  -- print ".............................................."
  print "Source Code:"

  putStrLn $ List.intercalate ";\n" $ List.map show ast
  print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  print "Desugared Form:"
  putStrLn $ List.intercalate ";\n" $ List.map show desugarized
  print "______________________________________________"
  ------------------------
  let (prg, zipper, insts) = translate ast
  print "Program State:"
  print prg
  print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  print $ right zipper
  print "Instructions:"
  print insts
  -- print ".............................................."
  -- print ".............................................."
  -- let iniVMState = State  { ctx = [ Frame { arguments = [], variables = [], caller = 0 } ]
  --                         , stack = Stack.empty
  --                         , gvm = Map.empty
  --                         , out = Seq.empty
  --                         , instaddr = 0
  --                         , memory = (0, Map.empty) }

  -- let isnt = setToInstruction 0 zipper
  -- let cs = runInstruction inst s pr
  -- let P { el = (inst, _) } = setToInstruction ia program
  -- let cs = runInstruction inst s pr
  -- -- let (out, stack, memory, s) = runProgram zipper prg iniVMState
  -- print "State:"
  -- -- print s
  -- print "//////////////////////////////////////////////"
  -- print "Stack:"
  -- print stack
  -- print "----------------------------------------------"
  -- print "Memory:"
  -- print memory