module Interpreter where

import AST (AST(..))


data Value
  = Expression AST
  | Object [Binding] AST
  deriving (Show)

type Binding = (String, Value)

data Ctx
  = Global [Binding]
  | Local [Binding] Ctx

-- addLocal :: Ctx -> Ctx
-- addLocal ctx = Local [] ctx

-- dropLocal :: Ctx -> Ctx
-- dropLocal Global bs = Global bs
-- dropLocal Local _ ctx = ctx

-- addToLocal :: Ctx -> Binding
-- addToLocal = undefined

addToCtx :: Binding -> Ctx -> Ctx
addToCtx (n, v) (Global bs) = Global $ (n, v) : bs
addToCtx (n , v) (Local bs ctx) = Local ((n, v) : bs) ctx

getFromBindings :: String -> [Binding] -> Maybe Value
getFromBindings _ [] = Nothing
getFromBindings name ((n, v) : bs) =
  if n == name
    then Just v
    else getFromBindings name bs

getFromLast :: String -> Ctx -> Maybe Value
getFromLast name (Global bs) =
  getFromBindings name bs
getFromLast name (Local bs ctx) =
  getFromBindings name bs

updateBindings :: Binding -> [Binding] -> [Binding]
updateBindings _ [] = [] -- should never happen
updateBindings (n, v) ((n', v') : bs) =
  if n == n'
    then (n, v) : bs
    else (n', v') : updateBindings (n, v) bs

updateCtx :: Ctx -> Binding -> Ctx
updateCtx ctx (n, v) =
  case ctx of
    Global bs ->
      case getFromBindings n bs of
        Nothing -> ctx -- this should never happen
        Just v' -> Global $ updateBindings (n, v) bs
    Local bs ctx' ->
      case getFromBindings n bs of
        Nothing -> Local bs $ updateCtx ctx' (n, v)
        Just v' -> Local (updateBindings (n, v) bs) ctx'

objectCtx :: AST -> [Binding] -- maybe free initCtx' from initCtx and call that -- but methods :(
objectCtx = undefined
-- smyslem je projit Object a ulozit do Bindings vsechny lokalni variables a metody a operatory
-- ObjectDef
-- ArrayDef

initCtx :: Ctx -> [AST] -> Either String Ctx
initCtx ctx [] = Right ctx
initCtx ctx (ast : asts) =
  case ast of
    FunctionDef name _ _ ->
      case getValue name ctx of
        Nothing ->
          case initCtx (addToCtx (name, Expression ast) ctx) asts of
            Left msg -> Left msg
            Right ctx -> Right ctx
        Just _ -> Left $ "Runtime Error: You can not redefine already defined function " ++ name ++ "."
    _ -> initCtx ctx asts

getValue :: String -> Ctx -> Maybe Value
getValue name ctx =
  case ctx of
    (Global bs) ->
      getFromBindings name bs
    (Local bs ctx) ->
      case getFromBindings name bs of
        Nothing -> getValue name ctx
        Just _ -> getFromBindings name bs

toIdentifierName :: AST -> String
toIdentifierName ast =
  undefined

evaluate :: [AST] -> IO (Either String Value)
evaluate asts = do
  r <- interpret asts $ Global []
  case r of
    Left msg -> do return $ Left msg
    Right (c, value) -> return $ Right value

interpret :: [AST] -> Ctx -> IO (Either String (Ctx, Value))
interpret asts ctx = do
  let r = initCtx ctx asts
  (case r of
    Left msg -> do
      return $ Left msg
    Right ctx -> do
      ps <- interpret' asts ctx
      return $ last ps)
  where
    interpret' :: [AST] -> Ctx -> IO [Either String (Ctx, Value)]
    interpret' [] _ = return []
    interpret' (ast : asts) ctx = do
      r <- interpretOne ast ctx
      (case r of
        Left msg -> return [Left msg]
        Right (ctx', head) -> do
          tail <- interpret' asts ctx'
          return $ Right (ctx', head) : tail)

interpretOne :: AST -> Ctx -> IO (Either String (Ctx, Value))
interpretOne ast ctx =
  case ast of
    Number i ->
      return $ Right (ctx, Expression ast)
    Boolean b ->
      return $ Right (ctx, Expression ast)
    Unit ->
      return $ Right (ctx, Expression ast)
    
    Block exprs ->
      interpret exprs ctx
    
    -- In Global/Top-level context - Function Declarations are hoisted, nowhere else they can occur
    FunctionDef _ _ _ ->
      return $ Right (ctx, Expression Unit)

    Let n v ->
      -- If in the current Context -> Error
      -- Otherwise -> add to Context
      case getFromLast n ctx of
        Just _ -> do
          -- print "Runtime Error: You can not redefine local variable " ++ n ++ "."
          return $ Left $ "Runtime Error: You can not redefine local variable " ++ n ++ "."
        Nothing -> do
          r <- interpretOne v ctx
          case r of
            Left msg -> return $ Left msg
            Right (ctx, value) ->
              return $ Right (addToCtx (n, value) ctx, Expression Unit)
      -- case ctx of
      --   Global _ -> (ctx, Expression Unit)
      --   Local _ _ ->
      --     case getFromLocal n of
      --       Just _ = ctx -> error "Runtime Error: You can not redefine local variable " ++ n ++ "."
      --       Nothing -> (addToCtx (n, interpretOne ctx v), Expression Unit)
    
    ObjectDef _ _ _ ->
      return $ Right (ctx, Object (objectCtx ast) ast)

    ReAssignment name value ->
      case getValue name ctx of
        Nothing -> do
          -- print "Runtime error: mutation of the variable " ++ name ++ " which does not exist."
          return $ Left $ "Runtime error: mutation of the variable " ++ name ++ " which does not exist."
        Just _ -> do
          r <- interpretOne value ctx
          case r of
            Left msg -> return $ Left msg
            Right (ctx, value) ->
              interpretOne ast $ updateCtx ctx (name, value)

    FieldReAssignment accessor value ->
      -- I shoudl register the value in the scope specific to the Object or Array
      -- decompose the accessor -> take two left-most and delegate the work to it?
      -- I need to lookup accessor in the ctx, check for all properties, reassign, update ctx
      undefined

    ArrayIndexReAssignment accessor value ->
      -- same thing as above
      undefined

    Identifier name ->
      case getValue name ctx of
        Nothing -> do
          -- print "Runtime error: referencing of the variable " ++ name ++ " which does not exist."
          return $ Left $ "Runtime error: referencing of the variable " ++ name ++ " which does not exist."
        Just value -> return $ Right (ctx, value)

    If condition _ _ -> undefined
      -- evaluateIf ast ctx

    While _ _ -> undefined
      -- evaluateWhile ast ctx

    ObjectFieldAccess _ _ _ -> undefined
      -- evaluateObjectFieldAccess ast ctx

    ArrayDef _ _ ->
      return $ Right (ctx, Object (objectCtx ast) ast)
 
    Application fn args ->
      case getValue (toIdentifierName fn) ctx of
        Nothing -> do
          -- print "Runtime Error: Cannot apply undefined function " ++ show fn ++ " to it's arguments " ++ show args ++ "."
          return $ Left $ "Runtime Error: Cannot apply undefined function " ++ show fn ++ " to it's arguments " ++ show args ++ "."
        Just (Expression (FunctionDef name params body)) -> undefined
          -- call interpret on the body
          -- before that - add new local Context with parameter names bound to the argument values
          -- ALSO - check if there is same number of Params as there is Args

    ArrayAccess exp member -> undefined

    Print format args -> do
      print format
      return $ Right (ctx, Expression Unit)

    Operation op left right -> do
      l <- interpretOne left ctx
      r <- interpretOne right ctx
      case (op, l, r) of
        (Plus, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Number $ a + b)
