module InterpreterSpec where

import Data.Either (fromRight)
import Test.Hspec
-- import Control.Exception (evaluate)

import Scanner (scan)
import Parser (parse)
import AST (AST(..), Operator(..))
import Interpreter (evaluate, Value(..))

toAst :: String -> [AST]
toAst = parse.scan

eval :: String -> IO Value
eval source =
  -- (evaluate.toAst) source >>= (\ v -> return $ fromRight (Error "Failed") v)
  fromRight (Error "Failed") <$> (evaluate $ toAst source)

spec :: Spec
spec = describe "Test the AST Interpreter" $ do
  describe "Programs with Arithmetics and Variables" $ do
    it "Evaluates Simple Program with Some Arithmetics" $ do
      eval "\
      \ begin\
      \  let a = 23;\
      \  let b = a + a;\
      \  b * b\
      \ end" `shouldReturn`
        Num 2116
    
    it "Evaluates Simple Program with Some Additional Arithmetics" $ do
      eval "\
      \ begin\
      \   let aa = 42;\
      \   aa <- 23;\
      \   let b = aa + aa;\
      \   b\
      \ end" `shouldReturn`
        Num 46

    it "Evaluates Simple Program with Simple Mutation" $ do
      eval "\
        \ let a = 23;\
        \ function foo () -> a;\
        \ foo();\
        \ a <- 42;\
        \ foo()" `shouldReturn`
          Num 42

    it "Evaluates Simple Program with Few Variables" $ do
      eval "let c = 4; let a = begin let a = 23; let b = 42; a + b + c end; a" `shouldReturn`
        Num 69
  
  describe "Programs with Boolean Arithmetics and Variables" $ do
    it "Evaluates Simple Program with some Bools" $ do
      eval "\
      \ let b = true;\
      \ let d = false;\
      \ let e = b | d;\
      \ e " `shouldReturn`
        Bool True


  describe "Programs with Arrays" $ do
    it "Evalutes Basic Array Construction" $ do
      eval "\
      \ let arr = array(10, 10);\
      \ arr[2]" `shouldReturn`
        Num 10

    it "Evalutes Program with Basic Array Constr but Inside Block" $ do
      eval "\
      \  (((begin\
      \   array(10, 10)\
      \ end)))[2]" `shouldReturn`
        Num 10

    it "Evaluates Program with Array Creation from Function" $ do
      eval "\
      \ let val = 0;\
      \ function get () ->\
      \   begin\
      \   let v = val;\
      \   val <- v + 1;\
      \   v\
      \   end;\
      \ let arr = array(10, get());\
      \ arr[5]" `shouldReturn`
        Num 0
    
    it "Evaluates Program with Array Construction from Iterator Function (within the Block)" $ do
      eval "\
      \ let val = 0;\
      \ function get () ->\
      \   begin\
      \   let v = val;\
      \   val <- v + 1;\
      \   v\
      \   end;\
      \ \
      \ let arr = array(10, begin get() end);\
      \ arr[8]" `shouldReturn`
        Num 8
  

  describe "Programs with Functions" $ do
    it "Evaluates Simple Program with Functions" $ do
      eval "\
      \ function foo (a, b) -> a + b;\
      \ function bar (a) -> foo(a, a);\
      \ let f = bar(23);\
      \ f" `shouldReturn`
        Num 46
    


  describe "Programs with Nested and Local Functions" $ do
    it "Evaluates Simple Program with Nested Functions" $ do
      eval "\
      \  begin\
      \    let x = 23;\
      \    function inner () ->\
      \      begin\
      \        let y = 42;\
      \        function mostInner () -> x + x + y;\
      \        mostInner()\
      \      end;\
      \    inner()\
      \  end" `shouldReturn`
        Num 88

    it "Evaluates Simple Program with Nested Functions" $ do
      eval "\
      \ begin\
      \   function foo (arg) ->\
      \     begin\
      \     function innerFn (arg2) ->\
      \       begin\
      \       function innermostFn (arg3) -> arg + arg2 + arg3;\
      \       innermostFn(arg2)\
      \       end;\
      \     innerFn(arg)\
      \     end;\
      \   foo(23)\
      \   end" `shouldReturn`
        Num 69
  
  describe "Programs with Recursion" $ do
    it "Evaluates Tail-Recursive Factorial for Number 10" $ do
      eval "\
      \  function fact (num) ->\
      \    begin\
      \    function faact (n, acc) ->\
      \        if (n == 0)\
      \        then acc\
      \        else faact(n - 1, acc * n);\
      \    faact(num, 1)\
      \    end;\
      \  fact(10)" `shouldReturn`
        Num 3628800
    
    it "Evaluates Head-Recursive Factorial for Number 10" $ do
      eval "\
      \  function fact (num) ->\
      \    if num == 0\
      \    then 1\
      \    else num * fact(num - 1);\
      \  fact(10)" `shouldReturn`
        Num 3628800

  describe "Programs with Loops" $ do
    it "Evaluates Simple Loop" $ do
      eval "\
      \  let val2 = 0;\
      \  let cond = true;\
      \  while cond\
      \    do\
      \    begin\
      \      val2 <- val2 + 23;\
      \      if val2 >= 10000 then cond <- false else unit\
      \    end;\
      \  val2" `shouldReturn`
        Num 10005
    
    it "Evaluates even Simpler Loop" $ do
      eval "\
      \  let test = 0;\
      \  while test < 100 do test <- test + 3;\
      \  test" `shouldReturn`
        Num 102

  describe "Programs with Objects" $ do
    it "Evaluates Simple Object's Member Function" $ do
      eval "\
      \ let c = object\
      \ begin\
      \   let foo = 23;\
      \   function fn () -> begin let foo = 42; this.foo end\
      \ end;\
      \ c.fn()" `shouldReturn`
        Num 23

    it "Evaluates Object's Member - which is also Object - Member Variable" $ do
      eval "\
      \ let a = object\
      \ begin\
      \   let local = object begin let val = 42; function f () -> this.val + 101 end;\
      \   function + (other) -> this.local + other.local;\
      \   function get () -> this.local\
      \ end;\
      \ a.local.val" `shouldReturn`
        Num 42
    
    it "Evalautes Object's Member - which is also Object - Function" $ do
      eval "\
      \  let a = object\
      \  begin\
      \    let local = object begin let val = 42; function f () -> this.val + 101 end;\
      \    function + (other) -> this.local + other.local;\
      \    function get () -> this.local\
      \  end;\
      \  a.get().f()" `shouldReturn`
        Num 143
