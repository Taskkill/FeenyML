module Main where

import Scanner (scan)
import Parser (parse)
import Tokens (Token(..))

-- import Lib

main :: IO ()
main = do
  let i = "begin let a = 23; let b = a + a; b * b end"
  putStrLn $ show $ parse $ scan i
