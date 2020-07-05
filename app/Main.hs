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
  -- print "----------------------------------------------"
  putStrLn "..."
  putStrLn "..."
  putStrLn "..."
  putStrLn "..."
  putStrLn "..."
  print "Compilation Process..."
  putStrLn "..."
  putStrLn "..."
  print "Desugarization Process:"
  -----------------------------------------------------
  let desugarized = desugarize ast
  -- r <- evaluate desugarized
  -- case r of
  --   Left msg -> print msg
  --   Right v -> print v
  -- print ".............................................."
  putStrLn "..."
  print "Original Source Code:"

  putStrLn $ List.intercalate ";\n" $ List.map show ast
  putStrLn "..."
  putStrLn "..."
  putStrLn "..."
  putStrLn "..."
  putStrLn "..."
  -- print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  print "Desugared Form:"
  putStrLn $ List.intercalate ";\n" $ List.map show desugarized
  -- putStrLn "..."
  -- putStrLn "..."
  -- putStrLn "..."
  -- putStrLn "..."
  -- putStrLn "..."
  -- print "Translation Process..."
  -- -- print "______________________________________________"
  -- ------------------------
  -- let (prg, zipper, insts) = translate ast
  -- print "VM Program State:"
  -- print prg
  -- -- print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  -- -- print $ right zipper
  -- putStrLn "..."
  -- putStrLn "..."
  -- putStrLn "..."
  -- print "VM Program Instructions:"
  -- print insts
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