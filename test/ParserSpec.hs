module ParserSpec where

import Test.Hspec
import Control.Exception (evaluate)

import Scanner (scan)
import Parser (parse)
import AST (AST(..), Operator(..))



toAst :: String -> AST
toAst = head.parse.scan

spec :: Spec
spec = describe "Test the Parser" $ do
  it "Parses Simple Arithmetic Expression" $ do
    toAst "23 + 42" `shouldBe`
      Operation Plus (Number 23) (Number 42)
  it "Parses Bool Expression" $ do
    toAst "true & (false | true)" `shouldBe`
      Operation And (Boolean True) (Operation Or (Boolean False) (Boolean True))
  it "Parses Unit Expression" $ do
    toAst "begin end" `shouldBe`
      Unit
  it "Parses If expression" $ do
    toAst "if true then 23 else 42" `shouldBe`
      If (Boolean True) (Number 23) (Number 42)
  it "Parses Block of Code" $ do
    toAst "begin 2 + 3; true end" `shouldBe`
      Block [ Operation Plus (Number 2) (Number 3), Boolean True ]
  it "Parses Let expression" $ do
    toAst "let var = 23" `shouldBe`
      Let "var" (Number 23)
  it "Parses Function Definition" $ do
    toAst "function foo (arg1, arg2, arg3) -> arg1 + arg3" `shouldBe`
      FunctionDef "foo" ["arg1", "arg2", "arg3"] (Operation Plus (Identifier "arg1") (Identifier "arg3"))
  it "Parses Reassignment of the Variable" $ do
    toAst "var <- 23" `shouldBe`
      ReAssignment "var" (Number 23)
  it "Parses Simple Object Definition" $ do
    toAst "object begin let local = 23 end" `shouldBe`
      ObjectDef Unit [Let "local" (Number 23)]
  it "Parses Complex Object Definition" $ do
    toAst "object begin let local = 23; function + (other) -> this.local + other.local end" `shouldBe`
      ObjectDef Unit
        [ Let "local" (Number 23)
        , OperatorDef Plus [ "other" ]
          (Operation Plus
            (ObjectFieldAccess This ["local"])
            (ObjectFieldAccess (Identifier "other") ["local"])
          ) ]
  it "Parses Array Definition" $ do
    toAst "array(10, 10)" `shouldBe`
      ArrayDef (Number 10) (Number 10)
  it "Parses Application of the Function to its Arguments" $ do
    toAst "fn(23, true)" `shouldBe`
      Application (Identifier "fn") [ Number 23, Boolean True ]
  it "Parses Array Access" $ do
    toAst "arr[0]" `shouldBe`
      ArrayAccess (Identifier "arr") (Number 0)
  it "Parses Complex Array Access" $ do
    toAst "arr[ var + 2 ]" `shouldBe`
      ArrayAccess (Identifier "arr") (Operation Plus (Identifier "var") (Number 2))
