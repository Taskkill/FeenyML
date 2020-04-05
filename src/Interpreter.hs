module Interpreter where

import AST (AST(..), Operator(..))


data Value
  -- = Expression AST
  = Object [Binding] AST -- [member] definition
  | Fn String [String] AST -- name [parameter] definition
  | Null
  | Num Int
  | Bool Bool
  | Error String
  deriving (Show)

type Binding = (String, Value)

data Scope
  = Global [Binding]
  | Local [Binding] Scope
  | Class [Binding] Scope
  deriving (Show)

addLocal :: Scope -> Scope
addLocal ctx = Local [] ctx

dropLocal :: Scope -> Scope
dropLocal (Global bs) = Global bs
dropLocal (Class _ ctx) = ctx
dropLocal (Local _ ctx) = ctx

getClassBindings :: Scope -> Maybe [Binding]
getClassBindings (Global _) = Nothing
getClassBindings (Class bs ctx) = Just bs
getClassBindings (Local _ ctx) = getClassBindings ctx

access :: [Binding] -> [String] -> Either String Value
access bs (name : []) =
  case getFromBindings name bs of
    Nothing -> Left $ "Runtime Error: property " ++ name ++ " does not exist on "
    Just v -> Right v
access bs (name : names) =
  case getFromBindings name bs of
    Just (Object b a) -> access b names
    Nothing -> Left $ "Runtime Error: property " ++ name ++ " does not exist on " -- please refactor to return Maybe
    Just v -> Left $ "Runtime Error: value" ++ show v ++ "does not have a property " ++ head names

addToBindings :: Binding -> Scope -> Scope
addToBindings (n, v) (Global bs) = Global $ (n, v) : bs
addToBindings (n , v) (Local bs ctx) = Local ((n, v) : bs) ctx
-- never should occurr that addToBindings should be called on (Class _ _)

getFromBindings :: String -> [Binding] -> Maybe Value
getFromBindings _ [] = Nothing
getFromBindings name ((n, v) : bs) =
  if n == name
    then Just v
    else getFromBindings name bs

getFromLast :: String -> Scope -> Maybe Value
getFromLast name (Global bs) =
  getFromBindings name bs
getFromLast name (Local bs ctx) =
  getFromBindings name bs
-- also can not be called on (Class _ _)

updateBindings :: Binding -> [Binding] -> [Binding]
updateBindings _ [] = [] -- should never happen
updateBindings (n, v) ((n', v') : bs) =
  if n == n'
    then (n, v) : bs
    else (n', v') : updateBindings (n, v) bs

bindParamsToArgs :: [String] -> [AST] -> Scope -> IO (Either String Scope)
bindParamsToArgs params args ctx =
  bindParamsToArgs' params args ctx []
    where
      bindParamsToArgs' [] [] ctx bs = return $ Right $ Local bs ctx
      bindParamsToArgs' (n : ns) (v : vs) ctx bs = do
        io <- interpretOne v ctx
        case io of
          (Left msg) -> return $ Left msg
          (Right (ctx, val)) -> bindParamsToArgs' ns vs ctx $ (n, val) : bs

-- TODO: refactor a bit? There's a lot of duplicities.
updateCtx :: Scope -> Binding -> Scope
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
    Class bs ctx' ->
      case getFromBindings n bs of
        Nothing -> Class bs $ updateCtx ctx' (n, v)
        Just v' -> Class (updateBindings (n, v) bs) ctx'

fill :: Int -> Scope -> AST -> IO (Either String (Scope, [Binding]))
fill size ctx ast =
  fill' size 0 ast ctx []
    where
      fill' :: Int -> Int -> AST -> Scope -> [Binding] -> IO (Either String (Scope, [Binding]))
      fill' 0 _ _ ctx bs = return $ Right (ctx, bs)
      fill' size index ast ctx bs = do
        io <- interpretOne ast ctx
        case io of
          Left msg -> return $ Left msg
          Right (c, v) ->
            fill' (size  - 1) (index + 1) ast c $ bs ++ [(show index, v)]

fromValue :: Value -> AST
fromValue (Fn name params def) = FunctionDef name params def
fromValue Null = Unit
fromValue (Num i) = Number i
fromValue (Bool b) = Boolean b
fromValue (Object _ ast) = ast

objectCtx :: AST -> Scope -> IO (Either String (Scope, [Binding])) -- maybe free initCtx' from initCtx and call that -- but methods :(
objectCtx (ObjectDef super definition) ctx = do
  io <- interpretOne super ctx
  case io of
    Left msg -> return $ Left msg
    Right (c, v) -> defToCtx definition c []
      where
        defToCtx :: [AST] -> Scope -> [Binding] -> IO (Either String (Scope, [Binding]))
        defToCtx [] ctx bs = return $ Right (ctx, bs)
        defToCtx ((Let name val) : asts) ctx bs = do
          io <- interpretOne val ctx
          case io of
            Left msg -> return $ Left msg
            Right (c, v) -> defToCtx asts c $ (name, v) : bs 
        
        defToCtx ((FunctionDef name params body) : asts) ctx bs =
          defToCtx asts ctx $ (name, Fn name params body) : bs

        defToCtx ((OperatorDef op params body) : asts) ctx bs =
          defToCtx asts ctx $ (show op, Fn (show op) params body) : bs

        defToCtx (exp : _) _ _ = return $ Left $ "Runtime Error: Object definition can not contain " ++ show exp ++ " ."
  -- ignore super for now TODO: interpret the super expression and take the bindings from it append them to current bindings

objectCtx (ArrayDef len init) ctx = do
  io <- interpretOne len ctx
  case io of
    Left msg -> return $ Left msg
    Right (c, Num i) ->
      case init of
        Application _ _ -> do
          io <- interpretOne init c
          case io of
            Left msg -> return $ Left msg
            Right (c, val) -> fill i c $ fromValue val
        _ -> fill i c init

initCtx :: Scope -> [AST] -> Either String Scope
initCtx ctx [] = Right ctx
initCtx ctx (ast : asts) =
  case ast of
    FunctionDef name ps def ->
      case getValue name ctx of
        Nothing ->
          case initCtx (addToBindings (name, Fn name ps def) ctx) asts of
            Left msg -> Left msg
            Right ctx -> Right ctx
        Just _ -> Left $ "Runtime Error: You can not redefine already defined function " ++ name ++ "."
    _ -> initCtx ctx asts

getValue :: String -> Scope -> Maybe Value
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

interpret :: [AST] -> Scope -> IO (Either String (Scope, Value))
interpret asts ctx = do
  let r = initCtx ctx asts
  (case r of
    Left msg -> do
      return $ Left msg
    Right ctx -> do
      ps <- interpret' asts ctx
      return $ last ps)
  where
    interpret' :: [AST] -> Scope -> IO [Either String (Scope, Value)]
    interpret' [] _ = return []
    interpret' (ast : asts) ctx = do
      r <- interpretOne ast ctx
      (case r of
        Left msg -> return [Left msg]
        Right (ctx', head) -> do
          tail <- interpret' asts ctx'
          return $ Right (ctx', head) : tail)

interpretOne :: AST -> Scope -> IO (Either String (Scope, Value))
interpretOne ast ctx =
  case ast of
    Number i ->
      return $ Right (ctx, Num i)
    Boolean b ->
      return $ Right (ctx, Bool b)
    Unit ->
      return $ Right (ctx, Null)
    
    Block exprs -> do
      e <- interpret exprs $ addLocal ctx
      case e of
        Left msg -> return $ Left msg
        Right (ctx, val) ->
          return $ Right (dropLocal ctx, val)
    
    -- Functions can be declared in any scope-level
    -- They are always hoisted
    FunctionDef _ _ _ ->
      return $ Right (ctx, Null)

    Let n v ->
      case getFromLast n ctx of
        Just _ -> do
          return $ Left $ "Runtime Error: You can not redefine local variable " ++ n ++ "."
        Nothing -> do
          r <- interpretOne v ctx
          case r of
            Left msg -> return $ Left msg
            Right (ctx, value) ->
              return $ Right (addToBindings (n, value) ctx, Null)
    
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
              return $ Right (updateCtx ctx (name, value), Null)

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
            Bool b ->
              if b
                then interpretOne then' c
                else interpretOne else' c
            _ -> return $ Left $ "Runtime Error: Condition " ++ show v ++ " is not a Bool value."

    While cond do' -> do
      io <- interpretOne cond ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, (Bool b)) ->
          if b
            then do
              io <- interpretOne do' c
              case io of
                Left msg -> return $ Left msg
                Right (c, _) -> interpretOne (While cond do') c
            else return $ Right (c, Null)

    ObjectFieldAccess obj [] -> interpretOne obj ctx
    ObjectFieldAccess obj (a:as) -> do
      case obj of
        This ->
          -- Check that there's (Class bindings _) in the Scope chain
          -- only get the value from the bindings
          -- which means - line 309 is not correct - it will get nearest identifier's value
          -- case getValue a ctx of
          --   Nothing -> return $ Left $ "Runtime Error: member " ++ a ++ " does not exist on the object."
          --   Just val -> interpretOne (ObjectFieldAccess (fromValue val) as) ctx
          case getClassBindings ctx of
            Nothing -> return $ Left "Runtime Error: This was used outside of the object scope."
            Just (bindings) ->
              case getFromBindings a bindings of
                Nothing -> return $ Left $ "Runtime Error: member " ++ a ++ " is not a member of the current object."
                Just v -> interpretOne (ObjectFieldAccess (fromValue v) as) ctx

        _ -> do
          io <- interpretOne obj ctx
          case io of
            Left msg -> return $ Left msg
            Right (c, Object bs def) ->
              case access bs (a:as) of
                Left msg -> return $ Left msg
                Right val -> return $ Right (ctx, val)

    ArrayDef _ _ -> do
      io <- objectCtx ast ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, b) -> return $ Right (c, Object b ast)
 
    Application (Identifier fname) args ->
      case getValue fname ctx of
        Nothing -> do
          return $ Left $ "Runtime Error: Cannot apply undefined function " ++ fname ++ " to it's arguments " ++ show args ++ "."
        Just (Fn _ params body) -> do
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
    
    Application (ObjectFieldAccess obj accessors) args -> do
      let method = last accessors
      let accessors' = init accessors
      io <-
        case accessors' of
          [] -> interpretOne obj ctx
          _ -> interpretOne (ObjectFieldAccess obj accessors') ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, (Object bindings ast)) ->
          case access bindings [method] of
            Left msg -> return $ Left msg
            Right (Fn _ params body) -> do
              io <- bindParamsToArgs params args $ Class bindings ctx --- TODO: Class
              case io of
                Left msg -> return $ Left msg
                Right c -> do
                  e <- interpretOne body c
                  case e of
                    Left msg -> return $ Left msg
                    Right (ctx, val) ->
                      return $ Right (dropLocal $ dropLocal ctx, val) -- first drop the local function context - then Object context
            _ -> return $ Left $ "Runtime Error: Application of object member " ++ method ++ " which is not a function."

    ArrayAccess accessible member -> do
      io <- interpretOne accessible ctx
      case io of
        Left msg -> return $ Left msg
        Right (c, v) ->
          case v of
            Object bs ast -> do
              io <- interpretOne member c
              case io of
                Left msg -> return $ Left msg
                Right (c, Num i) ->
                  case getFromBindings (show i) bs of
                    Nothing -> return $ Right (c, Null)
                    Just val -> return $ Right (c, val)
            _ -> return $ Left "Runtime Error: operator [] used on non Object type."

    -- TODO: implement
    Print format args -> do
      print $ show format ++ show args
      return $ Right (ctx, Null)

    -- TODO: implement the rest
    -- TODO: FIX: left side may mutate something which right side accesses
    Operation op left right -> do
      l <- interpretOne left ctx
      r <- interpretOne right ctx
      case (op, l, r) of
        (Plus, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Num $a + b)
        (Minus, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Num $a - b)
        (Multiply, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Num $a * b)
        (Divide, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Num $a `div` b) -- check if not division by zero
        (Modulo, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Num $a `mod` b)
        
        (Equal, (Right (_, Bool a)), (Right (_, Bool b))) ->
          return $ Right (ctx,  Bool $a == b)
        (Equal, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Bool $a == b)
        
        (UnEqual, (Right (_, Bool a)), (Right (_, Bool b))) ->
          return $ Right (ctx,  Bool $not $ a == b)
        (UnEqual, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Bool $not $ a == b)
        
        (Lesser, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Bool $a < b)
        (Greater, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Bool $a > b)
        (LesserEqual, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Bool $a <= b)
        (GreaterEqual, (Right (_, Num a)), (Right (_, Num b))) ->
          return $ Right (ctx,  Bool $a >= b)
        
        (And, (Right (_, Bool a)), (Right (_, Bool b))) ->
          return $ Right (ctx,  Bool $a && b)
        (Or, (Right (_, Bool a)), (Right (_, Bool b))) ->
          return $ Right (ctx,  Bool $a || b)
        _ -> do
          print (op, r)
          return $ Left "error"
