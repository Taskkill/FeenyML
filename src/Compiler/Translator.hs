module Compiler.Translator where

import AST (AST(..), Operator(..))
import VM.Program.Instruction (Instruction(..))
import qualified VM.Program.Instruction as I
-- import VM.State -- (State(..))
import VM.Program
import qualified VM.Program.Value as P
import qualified Data.Map.Strict as Map
import Data.Map.Strict ((!?))
import qualified Data.List as List
import qualified Data.String as String
import Compiler.Desugarizer (blocksToLambdas)


data Helper =
  H { localVarsCnt  :: Int
    , nestLevel     :: Int
    , frames        :: [[String]]
    , antiCP        :: Map.Map P.Value Int
    , labelCounter  :: Int }


initHelper :: Helper
initHelper = H
  { localVarsCnt = 0
  , nestLevel = 0
  , frames = []
  , antiCP = Map.singleton P.Null 0
  , labelCounter = 0 }

-- TODO: refactor into single function
translate :: [AST] -> (PProgram, Program)
translate asts =
  (state, program)
    where
      desugared = blocksToLambdas asts
      (state, i, h) = translate2 (initProgram, initHelper) desugared -- foldl translate' (initProgram, initHelper) asts
      program = instructions2Program i
      translate2 :: (PProgram, Helper) -> [AST] -> (PProgram, [Instruction], Helper)
      translate2 (program, helper) [] =
        (program, [], helper)
      translate2 (program, helper) (a : asts) =
        let
          (p, i, h) = translate' (program, helper) a
          (p', i', h') = translate2 (p, h) asts
        in
          (p', i ++ i', h')
  -- do stuff
  -- register all global functions
  -- local functions are gonna be translated to jumps
  -- then translate all AST Node into corresponding Program Instruction

findVar :: String -> [[String]] -> Maybe (Int, Int)
findVar = findVar' 0
  where
    findVar' :: Int -> String -> [[String]] -> Maybe (Int, Int)
    findVar' _ _ [[]] = Nothing
    findVar' i name (frame : frames) =
      case List.elemIndex name (List.reverse frame) of -- because the first var is at the and of the list with index 0
        Just i' -> Just (i, i')
        Nothing -> findVar' (i + 1) name frames

translateN :: Int -> (PProgram, Helper) -> [AST] -> (PProgram, [Instruction], Helper)
translateN = undefined
-- IMPORTANT: actuall instruction order needs to be reversed --> probably

initProgram :: PProgram
initProgram = PP
  { labels = Map.empty -- TODO: this needs to be replaced -- with actually pre-processed labels
  , constpool = Map.singleton 0 P.Null
  , globals = []
  , fns = [] } -- TODO: complete

translate' :: (PProgram, Helper)  -> AST -> (PProgram, [Instruction], Helper)
translate'
  ( program@PP { labels = l, constpool = cp, globals = gls, fns = fns }
  , helper@H { localVarsCnt = lvc, nestLevel = nl, frames = fr, antiCP = acp })
  ast =
    case ast of
      Number i ->
        case acp !? (P.Int i) of
          Just addr ->
            (program, [Lit addr], helper)
          Nothing ->
            let
              addr = Map.size cp
              cp' = Map.insert addr (P.Int i) cp
              acp' = Map.insert (P.Int i) addr acp
            in
              (program{ constpool = cp' }, [Lit addr], helper{ antiCP = acp' })

      Boolean b ->
        case acp !? (P.Bool b) of
          Just addr ->
            (program, [Lit addr], helper)
          Nothing ->
            let
              addr = Map.size cp
              cp' = Map.insert addr (P.Bool b) cp
              acp' = Map.insert (P.Bool b) addr acp
            in
              (program{ constpool = cp' }, [Lit addr], helper{ antiCP = acp' })
      
      Unit ->
        -- Null/Unit is ALWAYS present in both ConstPool and antiConstPool
        -- it is also given prominent address at the index 0
        (program, [Lit 0], helper)

      FunctionDef name args body ->
        let
          -- TODO: I am gonna rewrite this part in the future
          -- before compilation I will traverse the whole ast to transform local functions and block
          -- I will mind every function and register their names into some List
          -- this List is then going to initialize constpool with function names - so recursion is working
          -- therefore when I arrive here - no need to store the function name to the constpool - it's already there
          nmAddr = Map.size cp -- future address of the function name in the constpool
          cp' = Map.insert nmAddr (P.String name) cp -- name is stored in the constpool
          acp' = Map.insert (P.String name) nmAddr acp -- store name and addr into anti constpool too
          ac = length args -- number of fn's arguments
          fnAddr = nmAddr + 1 -- Map.size cp' -- future function address in the constpool
          cp'' = Map.insert fnAddr P.Null cp' -- placeholder Null is stored in the constpool
          gls' = fnAddr : gls -- function's address is added to the global slots
          fr = frames helper
          help = H { localVarsCnt = 0, nestLevel = nl + 1, frames = [] : fr, antiCP = acp', labelCounter = labelCounter helper }
          (s, b, h) = translate' (program { constpool = cp', globals = gls' }, help) body -- program and body instructions
          vc = List.length $ List.head $ frames h -- number of the function local variables
          -- it's List.last because frames add up from left
          fn = P.Function { P.nameInd = nmAddr, P.argsCnt = ac, P.varsCnt = vc, P.body = b } -- function finally created
          cp''' = constpool s
          cp'''' = Map.insert fnAddr fn cp''' -- replace the Null placeholder with actuall function
          acp'' = Map.insert fn fnAddr acp'
          program' = s { constpool = cp', fns = fn : fns } -- final program
          helper' = helper { antiCP = acp'' }
        in
          (program', [], helper')
      -- 

      -- TODO: Block will disappear
      Block exprs -> (program, [], helper)
      -- blok je v podstate anonymni lokalni funkce
      -- nema zadne argumenty
      -- pokud to takhle ale udelam, pak musim lokalni funkce implementovat jako skutecne funkce - zadne jumpy a labely
      -- i lokalni funkce musi jit do constpoolu, fns listu, global slots listu atd
      -- lokalni funkce tedy budou promotnute na globalni fce a s tim se poji i nutnost jim vytvorit unikatni identifikator
      -- navrhuji retezit jmena funkci pomoci operatoru @ napriklad:
      -- topFn@innerFn@mostNestedFn
      -- takhle bude prejmenovana kazda lokalni fce a jeji Call AST Node
      -- tahle transformace by se asi mela odehrat driv nez se bude delat samotnej preklad
      -- diky tomu uz pri prekladu bude vsechno spravne prejmenovany
      -- a blocky teda budou anonymni lokalni fce bez argumentu -- bohuzel nic jako funkce beze jmena FML nezna
      -- musim kazdemu bloku tedy nejake unikatni jmeno pridelit -- to asi nebude problem - proste zacnu s
      -- anonymous#0 ... anonymous#1 -- nebo block#0 ... block#1
      -- i tahle transformace se musi odehrat idealne pred kompilaci
      -- takze Block zmizi uplne a bude to jenom call do lokalni funkce

      -- consider two options
      -- A) treating Blocks as functions -- this will only work if local functions are implemented as real functions
      -- B) treating Blocks as jumps
      -- essentially I am going to implement Blocks as the local functions
      -- whichever impl will be chosen for loc. fns will also be chosen for the blocks

      Let name value ->
        let
          fr = frames helper
          fr' = (name : head fr) : tail fr -- add variable to the top-most frame and add this frame to the rest of the frames
          helper' = helper{ localVarsCnt = lvc + 1, frames = fr' }
          (program', instructions, h) = translate' (program, helper') value
          assign = SetIn 0 lvc
          instructions' = instructions ++ [assign]
        in
          (program', instructions', h)
        -- this variable's index is the value of lvc
        -- if nl is 0 then SetGlobal and use the name
        -- if nl is > 0 then SetLocal and use the index lbc
        -- if advanced stuff -> use SetIn and always index 0 - because it's local to the current frame + index lvc
      -- SetLocal or SetGlobal -- in both cases - when entering Context/Frame - variable is already declared

      ObjectDef super constructor -> undefined
      -- first translate super object to the code
      -- this code needs to be evaluated first - Pointer to the super is pushed to the stack
      -- then analyze constructor
        -- it needs to get all the local variables
        -- all the methods
        -- initial values of the local variables needs to be pushed to the Stack
        -- ofcourse they need to be stored to the memory and only Pointers are going to be pushed to the Stack
      -- then create Class structure -- store it in ConstPool then put the address to it to the instruction Object addr

      ReAssignment name value ->
        let
          fr = frames helper
          maybeCoords = findVar name fr

          (program', instructions, helper') = translate' (program, helper) value
        in
          case maybeCoords of
            Just (frIndex, varIndex) ->
              (program', instructions ++ [SetIn frIndex varIndex], helper')
            Nothing -> error $ "Compile error: variable " ++ name
              ++ " which you are trying to re-assign a value, is not in the scope."

        -- I have to find which frame the variable comes from
        -- in the helper.frames I go from the head to the tail of the each list of variables
        -- once I find it I have both indexes - index of the frame and index of the variable itself
        -- there is catch though - index of the var in the frame is reversed - 0 is first variable - at the end of the frame
        -- so this needs to be taken care of
        -- after that - it's just push the value onto the stack
        -- the value first needs to be translated to the bytecode
        -- it's program is first - it should push it to the Stack
        -- then SetIn index' index'' picks it up
        
        -- I am gonna go with the SetIn
        -- SetLocal or SetGlobal

      FieldReAssignment accessor value -> undefined
      -- SetSlot

      ArrayIndexReAssignment accessor value -> undefined
      -- SetSlot

      Identifier name ->
        let
          fr = frames helper
          maybeCoords = findVar name fr
        in
          case maybeCoords of
            Just (frIndex, varIndex) ->
              (program, [GetIn frIndex varIndex], helper)
            Nothing -> error $ "Compile error: variable " ++ name ++ " is not in the scope."

        -- this is supposed to look for variable with given name in the current frame chain
        -- once found --> it needs to get its value and push it to the stack
        -- see ReAssignment for inspiration - should be almost same
        -- if can not find --> compilation error
        -- when I find the index' and index'' --> use GetIn 

        -- instruction GetIn

      If condition then' else' ->
        let
          labelC = labelCounter helper
          -- now this number is number is unique

          helpr = helper{ labelCounter = labelC + 1 }
          
          (program', condInstr, helper') = translate' (program, helpr) condition
          (program'', thenInstr, helper'') = translate' (program', helper') then'
          (program''', elseInstr, helper''') = translate' (program'', helper'') else'

          -- I can prefix my labels with `labelC_` and be sure to never cause any conflicts
          prefix = show labelC ++ "_"
          thenL = prefix ++ "then"
          elseBL = prefix ++ "else:begin"
          elseEL = prefix ++ "else:end"

          cp = constpool program'''
          acp = antiCP helper'''
          --
          addr0 = Map.size cp
          -- now store first label name to the constpool and anti constpool
          cp' = Map.insert addr0 (P.String thenL) cp
          acp' = Map.insert (P.String thenL) addr0 acp
          -- now store the second label name to the constpool and anti constpool
          addr1 = addr0 + 1
          cp'' = Map.insert addr1 (P.String elseBL) cp'
          acp'' = Map.insert (P.String elseBL) addr1 acp'
          -- now store the third label name to the constpool and anti constpool
          addr2 = addr1 + 1
          cp''' = Map.insert addr2 (P.String elseEL) cp''
          acp''' = Map.insert (P.String elseEL) addr2 acp''
          -- OK
          instructions
            =  condInstr      -- instructions for condition
            ++ [Branch addr0] -- Branch - if truethish - jump to thenBegin
            ++ [Goto addr1]   -- goto elseBegin
            ++ [Label addr0]  -- label thenBegin
            ++ thenInstr      -- instructions for then
            ++ [Goto addr2]   -- goto elseEnd
            ++ [Label addr1]  -- label elseBegin
            ++ elseInstr      -- instructions for else
            ++ [Label addr2]  -- label elseEnd
        in
          (program''', instructions, helper''')

      While cond do' ->
        let
          labelC = labelCounter helper
          helpr = helper{ labelCounter = labelC + 1 }

          (program', condInstr, helper') = translate' (program, helpr) cond
          (program'', bodyInstr, helper'') = translate' (program', helper') do'

          -- I can prefix my labels with `labelC_` and be sure to never cause any conflicts
          prefix = show labelC ++ "_"
          loopBegin = prefix ++ "loop:begin"
          loopEnd = prefix ++ "loop:end"
          bodyBegin = prefix ++ "body:begin"

          cp = constpool program''
          acp = antiCP helper''
          --
          addr0 = Map.size cp

          cp' = Map.insert addr0 (P.String loopBegin) cp
          acp' = Map.insert (P.String loopBegin) addr0 acp

          addr1 = addr0 + 1

          cp'' = Map.insert addr1 (P.String loopEnd) cp'
          acp'' = Map.insert (P.String loopEnd) addr1 acp'

          addr2 = addr1 + 1

          cp''' = Map.insert addr2 (P.String bodyBegin) cp''
          acp''' = Map.insert (P.String bodyBegin) addr2 acp''
          -- OK
          instructions
            =  [Label addr0]  -- label loopBegin
            ++ condInstr      -- instructions for condition
            ++ [Branch addr2] -- Branch - if truethish - jump to the bodyBegin
            ++ [Goto addr1]   -- goto loopEnd
            ++ [Label addr2]  -- label bodyBegin
            ++ bodyInstr      -- instructions for body
            ++ [Label addr2]  -- goto loopBegin
            ++ [Label addr1]  -- label loopEnd
        in
          (program'', instructions, helper'')

      ObjectFieldAccess obj [] -> undefined
      -- GetSlot

      ObjectFieldAccess obj (a:as) -> undefined
      -- GetSlot -- chain of them

      ArrayDef size initvalue ->
        let
          cp = constpool program
          acp = antiCP helper
          newAddr = Map.size cp

          (program', insts, helper') =
            case size of
              Number i ->
                case acp !? (P.Int i) of
                  Just addr ->
                    (program, [Lit addr], helper)
                  Nothing ->
                    let
                      cp' = Map.insert newAddr (P.Int i) cp
                      acp' = Map.insert (P.Int i) newAddr acp
                    in
                      (program{ constpool = cp' }, [Lit newAddr], helper{ antiCP = acp' })
              _ -> -- it's expression
                translate' (program, helper) size -- translate the size expression --> put the value on the Stack
          
          (p', i', h') = translate' (program', helper') initvalue
        in
          (p', insts ++ i' ++ [ Array ], h')
        -- two types of array
        -- one of them is simple array with every element being same
        -- second one is when initvalue is block of code -- which is actually gonna be translated as function call
        -- so if the initvalue is function call then it will be evaluated again and again for each value

      Application (Identifier fname) args ->
        -- all function names are in the constpool
        -- if no (String fname) is found in anti constpool --> compile error

        case (antiCP helper) !? (P.String fname) of
          Nothing -> error $ "Compile error: calling function " ++ fname ++ " which is not defined."
          Just addr ->
            let
              argC = List.length args
              (prg', insts, help') = translateN argC (program, helper) args
            in
              (prg', insts ++ [Call addr argC], help')
      Application (ObjectFieldAccess obj accessors) args -> undefined

      -- resolve the whole accessor chain - then call the last one as method - chain of GetSlots
      -- CallSlot

      ArrayAccess accessible member -> undefined
      -- GetSlot

      AST.Print format args -> undefined
      -- Print
      -- push args to the Stack
      -- if the argument is expression it needs to be stored into the memory using Lit, Array, Object
      -- if the argument is variable it already is registered --> local in case its been registered in function
        -- global if its global variable
        -- also somehow local if it's inside block or local function -- this needs to be taken care of

      Operation op left right -> undefined
      -- CallSlot
