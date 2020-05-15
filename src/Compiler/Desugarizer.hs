module Compiler.Desugarizer where

import AST
import qualified Data.Map.Strict as Map
import Data.Map.Strict ((!))
import qualified Data.List as List

blocksToLambdas :: [AST] -> [AST]
blocksToLambdas =
  blocksToLambdas' 0 -- the number is evergrowing index of blocks --> each block has uniqe index
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
            -- NOW this is exception -- if function's body is block of code then this single block of code is OK
            -- any block of code nested inside this top level - function's body - however is not OK
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
          _ -> expr : blocksToLambdas' i exprs



localFnsToGlobal :: [AST] -> [AST]
localFnsToGlobal exprs =
  let
    translator = phase1 exprs "" Map.empty
  in
    phase2 exprs "" translator



-- Phase1 is just hoisting of all the functions defined on this level
-- this is needed so every function defined in whatever order, at the top or on bottom of the current scope
-- is always treated same -- as if they are declared before they can be used for the first time
phase1 :: [AST] -> String -> Map.Map String String -> Map.Map String String
phase1 exprs namespace translator =
  List.foldl phase1' Map.empty exprs
    where
      phase1' :: Map.Map String String -> AST -> Map.Map String String
      phase1' translator expr = 
        case expr of
          FunctionDef name args body ->
            Map.insert name (namespace ++ "@" ++ name) translator
          _ ->
            translator



-- Phase2 has to rename all FunctionDef names according to the translator
-- it also has to rename all Call expressions according to the translator
-- it also needs to walk through any other expression which could contain Call expression
-- while walking -> it needs to call phase2' on them
-- if it arrives to the AST which contains list of ASTs and introduces it's own scope <=> Block 
-- it needs to call phase1 on the list first
-- then it needs to call phase2 on the list too
phase2 :: [AST] -> String -> Map.Map String String -> [AST]
phase2 exprs namespace translator =
  List.map phase2' exprs
    where
      phase2' :: AST -> AST
      phase2' expr =
        case expr of
          FunctionDef name args (Block body) ->
            let
              translator' = phase1 body namespace translator
              body' = phase2 body namespace translator'
            in
              FunctionDef (translator ! name) args (Block body')
          
          FunctionDef name args body ->
            FunctionDef (translator ! name) args $ phase2' body
          
          Application (Identifier name) args ->
            Application (Identifier $ translator ! name) $ phase2 args namespace translator

          Let name expr ->
            Let name $ phase2' expr
          
          ReAssignment name expr ->
            ReAssignment name $ phase2' expr

          FieldReAssignment object'field expr ->
            FieldReAssignment object'field $ phase2' expr

          ArrayIndexReAssignment array'item expr ->
            ArrayIndexReAssignment array'item $ phase2' expr

          If condition then' else' ->
            If (phase2' condition) (phase2' then') (phase2' else')

          While condition body ->
            While (phase2' condition) (phase2' body)

          ArrayDef length initvalue ->
            ArrayDef (phase2' length) (phase2' initvalue)

          Print format args ->
            Print format $ phase2 args namespace translator          


-- foldlMapState :: ((a, s) -> (a, s)) -> s -> [a] -> [a]
-- foldlMapState _ _ [] = []
-- foldlMapState fn init (a : as) =
--   let
--     (a', s') = fn (a, init)
--   in
--     a' : foldlMapState fn s' as

-- localFnsToGlobal :: [AST] -> [AST]
-- localFnsToGlobal =
--   foldlMapState localFnsToGlobal' ("", Map.empty)
--     where
--       localFnsToGlobal' :: (AST, (String, Map.Map String String)) -> (AST, (String, Map.Map String String))
--       localFnsToGlobal' (expr, (namespace, translator)) =
--         case expr of
--           -- I want to take care only of cases which can contain Function definitions
--           -- on the top level there can be Function easily
--           -- but question is == should I generally go inside every Expression which could contain other expressions?
--           -- shoudl I go inside Expression like Let in or Reassignment


--           FunctionDef name args body -> undefined
--           -- if namespace is empty string then OK
--           -- if it contains some string -- put it together with `@` and name and store it also in translator
--           -- I also need to go through the body

--           -- OperatorDef op args body -> undefined
--           -- operators are only inside objects
--           -- I need to think about local functions in method
--           -- I should probably make them methods -- so not global to whole program just to the object/class

--           -- ObjectDef super definition -> undefined
--           -- what OperatorDef comment says

--           ReAssignment varname expr ->
--             let
--               (expr', state) = localFnsToGlobal' (expr, (namespace, translator))
--             in
--               (ReAssignment varname expr', state)

--           FieldReAssignment object expr ->
--             let
--               (expr', state) = localFnsToGlobal' (expr, (namespace, translator))
--             in
--               (FieldReAssignment object expr', state)

--           ArrayIndexReAssignment access epxr ->
--             let
--               (expr', state) = localFnsToGlobal' (expr, (namespace, translator))
--             in
--               (ArrayIndexReAssignment access expr', state)

--           If condition then' else' ->
--             let
--               (expr', state) = localFnsToGlobal' (then', (namespace, translator))



--           While condition body -> undefined
--           ArrayDef length initvalue -> undefined
--           Application callee params -> undefined
--           ArrayAccess indexable expr -> undefined
--           Print format params -> undefined
--           Operation op left right -> undefined

--           _ -> (expr, (namespace, translator))
