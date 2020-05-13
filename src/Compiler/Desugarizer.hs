module Compiler.Desugarizer where

import AST


blocksToLambdas :: [AST] -> [AST]
blocksToLambdas =
  blocksToLambdas' 0
    where
      blocksToLambdas' :: Int -> [AST] -> [AST]
      blocksToLambdas' _ [] = []
      blocksToLambdas' i (expr : exprs) =
        case expr of
          Block body -> undefined
            -- call blocksToLambdas' 0 on body
            -- first create FunctionDef -- name like 'block[i]'
            -- then create Call to that function
          FunctionDef name args body -> undefined
            -- call blocksToLambdas' 0 body
            -- that's it
          Let varname expr -> undefined
            -- call blocksToLambdas' 0 expr
            -- that's it
          OperatorDef op args body -> undefined
            -- call blocksToLambdas' 0 body
            -- that's it
          ObjectDef super definition -> undefined
            -- call blocksToLambdas' 0 definition
            -- that's it
          ReAssignment varname expr -> undefined
            -- call blocksToLambdas' 0 expr
            -- that's it
          FieldReAssignment object expr -> undefined
            -- since I believe object can only be something like name . name2 . name3 ...
            -- call blocksToLambdas' 0 expr
            -- that's it
          ArrayIndexReAssignment access epxr -> undefined
            -- since I believe similar holds for this
            -- call blocksToLambdas' 0 expr
          If condition then' else' -> undefined
            -- check if each of them is a Block
            -- if so -> undefined first declare local function before If and then call it
          While condition body -> undefined
            -- same as If
          ArrayDef length initvalue -> undefined
            -- same
          Application callee params -> undefined
            -- walk through all parameters and if any of them is Block
            -- the function needs to be put before application
            -- and the actuall parameter is just function call
          ArrayAccess indexable expr -> undefined
            -- check expr for being Block
          Print format params -> undefined
            -- essentially Application --> undefined same treatment
          Operation op left right -> undefined
            -- left and right both check for being Block
          _ -> undefined