module ScannerSpec where

import Test.Hspec
import Control.Exception (evaluate)

import Scanner (scan)
import Tokens(Token(..))

spec :: Spec
spec = describe "Test the Scanner/Tokenizer" $ do
  describe "Accepts Simple Arithmetics" $ do
    it "Accepts Expression `2 + 5`" $ do
      scan                 "2 + 5" `shouldBe` [Number 2, Plus, Number 5]
  describe "Accepts Simple Special Characters" $ do
    it "Accepts `( ) [ ] ; . , = + - * / % < > | &`" $ do
      scan      "( ) [ ] ; . , = + - * / % < > | &" `shouldBe`
        [ LeftParen
        , RightParen
        , LeftBracket
        , RightBracket
        , Semicolon
        , Dot
        , Comma
        , Be
        , Plus
        , Minus
        , Multiply
        , Divide
        , Modulo
        , Lesser
        , Greater
        , Or
        , And ]
  describe "Accepts Composite Special Characters Keywords" $ do
    it "Accepts `-> <- <= >= == !=`" $ do
      scan      "-> <- <= >= == !=" `shouldBe`
        [ RightArrow
        , LeftArrow
        , LesserEqual
        , GreaterEqual
        , Equal
        , UnEqual ]
  describe "Accepts Keywords consisting of Letters" $ do
    it "Accepts `while object if else then let begin end this print function do extends`" $ do
      scan      "while object if else then let begin end this print function do extends" `shouldBe`
        [ While
        , Object
        , If
        , Else
        , Then
        , Let
        , Begin
        , End
        , This
        , Print
        , Function
        , Do
        , Extends ]
  describe "Accepts Simple Value Literals and Constructors" $ do
    it "Accepts `true false array unit`" $ do
      scan      "true false array unit" `shouldBe`
        [ T
        , F
        , Array
        , Unit ]
    it "Accepts Numerical Values" $ do
      scan "23 42" `shouldBe` [ Number 23, Number 42 ]
    it "Accepts Identifier Names" $ do
      scan "simple simpleWithCamelCase complex23" `shouldBe`
        [ Identifier "simple"
        , Identifier "simpleWithCamelCase"
        , Identifier "complex23" ]
