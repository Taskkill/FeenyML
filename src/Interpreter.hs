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
  deriving (Show)

addLocal :: Ctx -> Ctx
addLocal ctx = Local [] ctx

dropLocal :: Ctx -> Ctx
dropLocal (Global bs) = Global bs
dropLocal (Local _ ctx) = ctx

addToBindings :: Binding -> Ctx -> Ctx
addToBindings (n, v) (Global bs) = Global $ (n, v) : bs
addToBindings (n , v) (Local bs ctx) = Local ((n, v) : bs) ctx

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

bindParamsToArgs :: [String] -> [AST] -> Ctx -> IO (Either String Ctx)
bindParamsToArgs params args ctx =
  bindParamsToArgs' params args ctx []
    where
      bindParamsToArgs' [] [] ctx bs = return $ Right $ Local bs ctx
      bindParamsToArgs' (n : ns) (v : vs) ctx bs = do
        io <- interpretOne v ctx
        case io of
          (Left msg) -> return $ Left msg
          (Right (ctx, val)) -> bindParamsToArgs' ns vs ctx $ (n, val) : bs

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

fill :: Int -> Ctx -> AST -> IO (Either String (Ctx, [Binding]))
fill size ctx ast =
  fill' size 0 ast ctx []
    where
      fill' :: Int -> Int -> AST -> Ctx -> [Binding] -> IO (Either String (Ctx, [Binding]))
      fill' 0 _ _ ctx bs = return $ Right (ctx, bs)
      fill' size index ast ctx bs = do
        io <- interpretOne ast ctx
        case io of
          Left msg -> return $ Left msg
          Right (c, v) ->
            fill' (size  - 1) (index + 1) ast c $ bs ++ [(show index, v)]

fromValue :: Value -> AST
fromValue (Expression ast) = ast
fromValue (Object _ ast) = ast

objectCtx :: AST -> Ctx -> IO (Either String (Ctx, [Binding])) -- maybe free initCtx' from initCtx and call that -- but methods :(
objectCtx (ArrayDef len init) ctx = do
  io <- interpretOne len ctx
  case io of
    Left msg -> return $ Left msg
    Right (c, Expression (Number i)) ->
      case init of
        Application _ _ -> do
          io <- interpretOne init c
          case io of
            Left msg -> return $ Left msg
            Right (c, val) -> fill i c $ fromValue val
        _ -> fill i c init
-- smyslem je projit Object a ulozit do Bindings vsechny lokalni variables a metody a operatory
-- ObjectDef

initCtx :: Ctx -> [AST] -> Either String Ctx
initCtx ctx [] = Right ctx
initCtx ctx (ast : asts) =
  case ast of
    FunctionDef name _ _ ->
      case getValue name ctx of
        Nothing ->
          case initCtx (addToBindings (name, Expression ast) ctx) asts of
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
    
    Block exprs -> do
      e <- interpret exprs $ addLocal ctx
      case e of
        Left msg -> return $ Left msg
        Right (ctx, val) ->
          return $ Right (dropLocal ctx, val)
    
    -- Functions can be declared in any scope-level
    -- They are always hoisted
    FunctionDef _ _ _ ->
      return $ Right (ctx, Expression Unit)

    Let n v ->
      case getFromLast n ctx of
        Just _ -> do
          return $ Left $ "Runtime Error: You can not redefine local variable " ++ n ++ "."
        Nothing -> do
          r <- interpretOne v ctx
          case r of
            Left msg -> return $ Left msg
            Right (ctx, value) ->
              return $ Right (addToBindings (n, value) ctx, Expression Unit)
    
    ObjectDef _ _ -> do
      io <- (objectCtx ast ctx)
      case io of
        Left msg -> return $ Left msg
        Right (c, b) -> return $ Right (c, Object b ast)

    ReAssignment name value ->
      case getValue name ctx of
        Nothing -> do
          return $ Left $ "Runtime error: mutation of the variable " ++ name ++ " which does not exist."
        Just _ -> do
          r <- interpretOne value ctx
          case r of
            Left msg -> return $ Left msg
            Right (ctx, value) ->
              return $ Right (updateCtx ctx (name, value), Expression Unit)

    -- TODO: implement
    FieldReAssignment accessor value ->
      -- I shoudl re-register the value in the scope specific to the Object or Array
      -- decompose the accessor -> take two left-most and delegate the work to it?
      -- I need to lookup accessor in the ctx, check for all properties, reassign, update ctx
      undefined

    -- TODO: implement
    ArrayIndexReAssignment accessor value ->
      -- same thing as above
      undefined

    Identifier name ->
      case getValue name ctx of
        Nothing -> do
          return $ Left $ "Runtime error: referencing of the variable " ++ name ++ " which does not exist."
        Just value -> return $ Right (ctx, value)

    If condition then' else' -> do
      io <- interpretOne condition ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, v) ->
          case v of
            Expression (Boolean b) ->
              if b
                then interpretOne then' c
                else interpretOne else' c
            _ -> return $ Left $ "Runtime Error: Condition " ++ show v ++ " is not a Bool value."

    -- TODO: implement
    While _ _ -> undefined
    -- evaluate the condition
    -- take new context and evaluate? the body --- body does not necessarily get new context
    -- again - evaluate condition with brand new context
    -- evaluate the body again?
    -- continue until condition is true

    -- TODO: implement
    ObjectFieldAccess _ _ _ -> undefined
      -- evaluateObjectFieldAccess ast ctx

    ArrayDef _ _ -> do
      io <- objectCtx ast ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, b) -> return $ Right (c, Object b ast)
 
    Application (Identifier fname) args ->
      case getValue fname ctx of
        Nothing -> do
          return $ Left $ "Runtime Error: Cannot apply undefined function " ++ fname ++ " to it's arguments " ++ show args ++ "."
        Just (Expression (FunctionDef _ params body)) -> do
          io <- bindParamsToArgs params args ctx
          case io of
            Left msg -> return $ Left msg
            Right c -> do
              e <- interpretOne body c
              case e of
                Left msg -> return $ Left msg
                Right (ctx, val) ->
                  return $ Right (dropLocal ctx, val)
          -- ALSO - check if there is same number of Params as there is Args

    ArrayAccess accessible member -> do
      io <- interpretOne accessible ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, v) ->
          case v of
            Expression _ -> return $ Left "Runtime Error: operator [] used on non Object type."
            Object bs ast -> do
              io <- interpretOne member c
              case io of
                Left msg -> return $ Left msg
                Right (c, Expression (Number i)) ->
                  case getFromBindings (show i) bs of
                    Nothing -> return $ Right (c, Expression Unit)
                    Just val -> return $ Right (c, val)

    -- TODO: implement
    Print format args -> do
      print $ show format ++ show args
      return $ Right (ctx, Expression Unit)

    -- TODO: implement the rest
    -- TODO: FIX: left side may mutate something which right side accesses
    Operation op left right -> do
      l <- interpretOne left ctx
      r <- interpretOne right ctx
      case (op, l, r) of
        (Plus, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Number $ a + b)
        (Minus, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Number $ a - b)
        (Multiply, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Number $ a * b)
        (Divide, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Number $ a `div` b) -- check if not division by zero
        (Modulo, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Number $ a `mod` b)
        
        (Equal, (Right (_, Expression (Boolean a))), (Right (_, Expression (Boolean b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a == b)
        (Equal, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a == b)
        
        (UnEqual, (Right (_, Expression (Boolean a))), (Right (_, Expression (Boolean b)))) ->
          return $ Right (ctx, Expression $ Boolean $ not $ a == b)
        (UnEqual, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Boolean $ not $ a == b)
        
        (Lesser, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a < b)
        (Greater, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a > b)
        (LesserEqual, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a <= b)
        (GreaterEqual, (Right (_, Expression (Number a))), (Right (_, Expression (Number b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a >= b)
        
        (And, (Right (_, Expression (Boolean a))), (Right (_, Expression (Boolean b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a && b)
        (Or, (Right (_, Expression (Boolean a))), (Right (_, Expression (Boolean b)))) ->
          return $ Right (ctx, Expression $ Boolean $ a || b)
        _ -> do
          print (op, r)
          return $ Left "error"
