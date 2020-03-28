{
module Parser where

import qualified Tokens as Token
import AST (AST(..), Operator(..))
}

%name parse
%tokentype { Token.Token }
%error { parserError }

%token
              '('                                                             { Token.LeftParen }
              ')'                                                             { Token.RightParen }
              '['                                                             { Token.LeftBracket }
              ']'                                                             { Token.RightBracket }
              ';'                                                             { Token.Semicolon }
              '.'                                                             { Token.Dot }
              ','                                                             { Token.Comma }
              larrow                                                          { Token.LeftArrow }
              rarrow                                                          { Token.RightArrow }
              '='                                                             { Token.Be }

              '+'                                                             { Token.Plus }
              '-'                                                             { Token.Minus }
              '*'                                                             { Token.Multiply }
              '/'                                                             { Token.Divide }
              '%'                                                             { Token.Modulo }
              leq                                                             { Token.LesserEqual }
              greq                                                            { Token.GreaterEqual }
              '<'                                                             { Token.Lesser }
              '>'                                                             { Token.Greater }
              '|'                                                             { Token.Or }
              '&'                                                             { Token.And }
              eq                                                              { Token.Equal }
              uneq                                                            { Token.UnEqual }

              while                                                           { Token.While }
              object                                                          { Token.Object }
              if                                                              { Token.If }
              else                                                            { Token.Else }
              then                                                            { Token.Then }
              true                                                            { Token.T }
              false                                                           { Token.F }
              array                                                           { Token.Array }
              unit                                                            { Token.Unit }
              let                                                             { Token.Let }
              begin                                                           { Token.Begin }
              end                                                             { Token.End }
              this                                                            { Token.This }
              print                                                           { Token.Print }
              function                                                        { Token.Function }
              do                                                              { Token.Do }
              extends                                                         { Token.Extends }

              identifier                                                      { Token.Identifier $$ }
              number                                                          { Token.Number $$ }
              string                                                          { Token.String $$ }

%nonassoc '>' '<' eq uneq leq greq
%left '|' '&'
%left '-' '+'
%left '*' '/' '%'
%%

Program         :: { [AST] } 
                : Expressions                                                 { $1 }
                | {- empty -}                                                 { [] }

Expressions     :: { [AST] }
                : Expressions ';' Expression                                  { $1 ++ [$3] }
                | Expression                                                  { [$1] }

Operator        :: { Operator }
                : '*'                                                         { Multiply }
                | '+'                                                         { Plus }
                | '-'                                                         { Minus }
                | '/'                                                         { Divide }
                | '%'                                                         { Modulo }
                | uneq                                                        { UnEqual }
                | eq                                                          { Equal }
                | '<'                                                         { Lesser }
                | '>'                                                         { Greater }
                | leq                                                         { LesserEqual }
                | greq                                                        { GreaterEqual }
                | '&'                                                         { And }
                | '|'                                                         { Or }

Literal         :: { AST }
                : number                                                      { Number $1 }
                | false                                                       { Boolean False }
                | true                                                        { Boolean True }
                | unit                                                        { Unit }
                | begin end                                                   { Unit }
                | '(' Literal ')'                                             { $2 -- maybe delete }

Identifier      :: { String }
                : identifier                                                  { $1 }
                | '(' Identifier ')'                                          { $2 }

Expression      :: { AST }
                : Function_Def                                                { $1 }
                | Object_Def                                                  { $1 }
                | Variable_Def                                                { $1 }
                | Object_Field                                                { $1 }
                | Conditional                                                 { $1 }
                | Loop                                                        { $1 }
                | Mutation                                                    { $1 }
                | Print                                                       { $1 }

                | Expression Operator Expression                              { Operation $2 $1 $3 }

                | Block                                                       { $1 }
                | Application                                                 { $1 }
                | Array_Def                                                   { $1 }
                | Array_Access                                                { $1 }
                | Identifier                                                  { Identifier $1 }
                | Literal                                                     { $1 }
                | '(' Expression ')'                                          { $2 }


Function_Def    :: { AST }
                : function identifier '(' Param_List ')' rarrow Expression    { FunctionDef $2 $4 $7 }

Variable_Def    :: { AST }
                : let identifier '=' Expression                               { Let $2 $4 }

Array_Def       :: { AST }
                : array '(' Expression ',' Expression ')'                     { ArrayDef $3 $5 }

Operator_Def    :: { AST }
                : function Operator '(' Param_List ')' rarrow Expression      { OperatorDef $2 $4 $7 }

Extends         :: { AST }
                : extends Expression                                          { $2 }
                | {- empty -}                                                 { Unit }

Object_Def      :: { AST }
                : object Extends begin Object_Body end                        { ObjectDef $2 $4 }

Object_Body     :: { [AST] }
                : Member                                                      { [$1] }
                | Object_Body ';' Member                                      { $1 ++ [$3] }
                | {- empty -}                                                 { [] }

Member          :: { AST }
                : Variable_Def                                                { $1 }
                | Function_Def                                                { $1 }
                | Operator_Def                                                { $1 }

Mutation        :: { AST }
                : identifier larrow Expression                                { ReAssignment $1 $3 }
                | Object_Field larrow Expression                              { FieldReAssignment $1 $3 }
                | Array_Access larrow Expression                              { ArrayIndexReAssignment $1 $3 }

Conditional     :: { AST }
                : if Expression then Expression Else_M                        { If $2 $4 $5 }

Else_M          :: { AST }
                : else Expression                                             { $2 }
                | {- empty -}                                                 { Unit }

Loop            :: { AST }
                : while Expression do Expression                              { While $2 $4 }

Block           :: { AST }
                : begin Expressions ';' Expression end                        { Block $ $2 ++ [$4] }
                | begin Expression end                                        { Block [$2] }

AccIndAble      :: { AST }
                : Object_Field                                                { $1 }
                | '(' Object_Field ')'                                        { $2 }

                | Block                                                       { $1 }
                | '(' Block ')'                                               { $2 }

                | Application                                                 { $1 }
                | '(' Application ')'                                         { $2 }

                | Array_Access                                                { $1 }
                | '(' Array_Access ')'                                        { $2 }

                | Identifier                                                  { Identifier $1 }

                | '(' AccIndAble ')'                                          { $2 -- this definitely helps }

Accessible      :: { AST }
                : Object_Def                                                  { $1 }
                | '(' Object_Def ')'                                          { $2 }

                | AccIndAble                                                  { $1 }
                | '(' Accessible ')'                                          { $2 -- not sure if this helps anything }

Object_Field    :: { AST }
                : Accessible '.' Field_Seq                                    { ObjectFieldAccess $1 $3 }
                | this '.' Field_Seq                                          { ObjectFieldAccess This $3 }
                | this                                                        { This }

Field_Seq       :: { [String] }
                : Identifier '.' Field_Seq                                    { $1 : $3 }
                | Identifier                                                  { [$1] }

Param_List      :: { [String] }
                : Param_List ',' identifier                                   { $1 ++ [$3] }
                | identifier                                                  { [$1] }
                | {- empty -}                                                 { [] }

Arg_List        :: { [AST] }
                : Arg_List ',' Expression                                     { $1 ++ [$3] }
                | Expression                                                  { [$1] }
                | {- empty -}                                                 { [] }

Callable        :: { AST }
                : Identifier                                                  { Identifier $1 }
                | Object_Field                                                { $1 }

Application     :: { AST }
                : Callable '(' Arg_List ')'                                   { Application $1 $3 }

Indexable       :: { AST }
                : Array_Def                                                   { $1 }
                | '(' Array_Def ')'                                           { $2 }

                | AccIndAble                                                  { $1 }
                | '(' Indexable ')'                                           { $2 -- not sure if this helps anything }

Array_Access    :: { AST }
                : Indexable '[' Expression ']'                                { ArrayAccess $1 $3 }

Print           :: { AST }
                : print '(' string ',' Arg_List ')'                           { Print $3 $5 }

{
parserError :: [Token.Token] -> a
parserError _ = error $ "Parse error"
}