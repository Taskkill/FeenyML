# feenyml

programming language inspired by [https://github.com/CuppoJava/Feeny/](https://github.com/CuppoJava/Feeny/)

## Project consists of:
- ### Lexer
- ### Parser
- ### AST Interpreter (Mostly Complete - the good parts are done - some OOP features are not)
- ### Compiler (Incomplete)
  - #### Desugarizer
  - #### Actual Translator (Incomplete)
- ### VM (Partially Done)


## Tech:
- ### Lexer is generated with Alex from `grammar/scanner.x`
- ### Parser is generated with Happy from `grammar/parser.y`
- ### AST Intepreter is trivial and not really best piece of Haskell code ever - you have been warned
- ### Compiler is vastly unfinished - really great part is Desugarizer which I kinda like
- ### VM is partially implemented - I have done a lot of work here - but right now I am not sure how much is left


FeenyML is very simple programming language.

Syntax looks like this:


Variable declaration:
```
let c = 4;

let a =
  begin
    let a = 23;
    let b = 42;
    a + b + c
  end;
a
```


Loops:
```
let val2 = 0;
let cond = true;

while cond
  do
  begin
    val2 <- val2 + 23;
    if val2 >= 10000 then cond <- false else unit
  end;
val2;

let test = 0;
while test < 100 do test <- test + 3;

test
```


#### After each line of code there must be semicolon - only exception is the last line - after which it must not be placed.


Blocks:
```
begin
  let var = 23
end
```

Block is a expression. It returns value of the last expression inside of it. Once again - each line of code has to end with semicolon except the last one.

#### Similarly to the block - returning value of it's last expression - FML program returns (exits with) the value of it's last expression. (The one without the semicolon.)



Short Functions:
```
function foo (a, b) -> a + b;

function bar (a) -> foo(a, a);

bar (4)
```



Complicated Functions:
```
function fact (num) ->
  if num == 0
  then 1
  else num * fact(num - 1);

fact(10)
```



You can also declare function inside code blocks. These are local to the block's scope.
```
begin
  let x = 23;

  function inner () ->
    begin
      let y = 42;
      function mostInner () -> x + x + y;
      mostInner()
    end;

  inner()
end
```



You can use this to declare functions inside functions and have a nice and clean code:
```
function fact (num) ->
  begin
  function faact (n, acc) ->
      if (n == 0)
      then acc
      else faact(n - 1, acc * n);
  faact(num, 1)
  end;

fact(10)
```


## AST Interpreter

You can run various examples in the `codes/` directory.
Program reads from the std-in so you can write your snippets in terminal.

You can run examples like:

`stack run evaluator-exe < codes/faact.fml`

or you can see almost complete output of `stack run feenyml-exe < codes/faact.fml` there you will see some compilation - specificaly desugarization - info.



Speaking of which - first part of the compilation is desugarization of the code.

We were to target Feeny bytecode with it's stack oriented VM. [https://www.dropbox.com/s/2jzr5pzh3oah8un/ex3.pdf](https://www.dropbox.com/s/2jzr5pzh3oah8un/ex3.pdf)

For that to work I needed to desugarize both code blocks - because that's something the original Feeny does not know.
And also local functions - I find them very nice addition to my language so I embraced them as much as possible. Our goal was to not implement closure - but next best thing to having closures is to have local functions, which you can invoke and they will be able to access surrounding context of the local block. I consider it really neat.

However both of them must go before compilation. Feeny VM supports only global functions.


First - blocks are desugarized into functions - local blocks are thus desugarized into local functions.

Second - all local functions are desugarized into something like "global" functions. They are not really global, but they all have globally unique identifier. This identifier is created by chaining names of the surround functions.

This is important and usefull later - because I extended the standard VM Instructionset with two special instructions - SetIn _ _ and GetIn _ _. These are generalizations of more specific GetLocal/SetLocal and GetGlobal/SetGlobal. They allow to specify in which parenting frame specific variable should be looked up for.

Then all functions can finally be treated as global functions and can live in the same namespace together without conflicts and without loosing any features.



Example Below:
```
function foo (arg) ->
  begin
  function innerFn (arg2) ->
    begin
    function innermostFn (arg3) -> arg + arg2 + arg3;
    innermostFn(arg2)
    end;
  innerFn(arg)
  end;
foo(23)
```

Will be desugarized to:
```
function foo (arg) ->
  begin
    function foo@innerFn (arg2) ->
      begin
        function foo@innerFn@innermostFn (arg3) -> arg + arg2 + arg3
    
        foo@innerFn@innermostFn(arg2)
      end

    foo@innerFn(arg)

  end;

foo(23)
```


As you can see - function blocks are not desugarized - of course - they are very much needed to stay the way they are.