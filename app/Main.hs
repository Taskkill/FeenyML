module Main where

import Tokens (Token(..))
import Scanner (scan)
import Parser (parse)
import Interpreter (evaluate)

-- import Lib

main :: IO ()
main = do
  i <- getContents
  let ast = parse $ scan i
  r <- evaluate ast
  case r of
    Left msg -> print msg
    Right v -> print v