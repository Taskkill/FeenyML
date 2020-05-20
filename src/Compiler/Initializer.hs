module Compiler.Initializer where

import qualified Data.List as List

import AST (AST(..))

allFns :: [AST] -> [(String, Int)]
allFns (expr : exprs) =
  case expr of
    FunctionDef name params (Block body) ->
      (name, List.length params) : allFns body ++ allFns exprs
    
    FunctionDef name params body ->
      (name, List.length params) : allFns exprs

    _ -> allFns exprs