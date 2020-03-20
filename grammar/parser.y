{
module Parser where

import qualified Tokens as Token
import AST (AST(..))
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

TopLevel        :: { [AST] }
                : Expression Semi_M                                           { [$1] }
                | Expression Expression_Seq Semi_M                            { $1 : $2 }
                | {- empty -}                                                 { [] }


Expression_Seq :: { [AST] }
                : ';' Expression Expression_Seq                               { $2 : $3 }
                | {- empty -}                                                 { [] }

Semi_M          :: { () }
                : ';'                                                         { () }
                | {- empty -}                                                 { () }


Operator        :: { AST }
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

Expression      :: { AST }
                : Function_Def                                                { $1 }
                | Object_Def                                                  { $1 }
                | Variable_Def                                                { $1 }
                | Object_Field                                                { $1 }
                | Conditional                                                 { $1 }
                | Loop                                                        { $1 }
                | Mutation                                                    { $1 }
                | Print                                                       { $1 }
                | Operation                                                   { $1 }

Function_Def    :: { AST }
                : function identifier '(' Param_List ')' rarrow Expression    { FunctionDef $2 $4 $7 }

Variable_Def    :: { AST }
                : let identifier '=' Expression                               { Let $2 $4 }

Array_Def       :: { AST }
                : array '(' Expression '.' Expression ')'                     { ArrayDef $3 $5 }

Operator_Def    :: { AST }
                : function Operator '(' Param_List ')' rarrow Expression      { OperatorDef $2 $4 $7 }

Extends         :: { AST }
                : extends Expression                                          { $2 }

Object_Def      :: { AST }
                : object Param_List Extends begin Object_Body end             { ObjectDef $3 $2 $5 }

Object_Body     :: { [AST] }
                : Member Semi_M                                               { [$1] }
                | Member Member_Seq Semi_M                                    { $1 : $2 }
                | {- empty -}                                                 { [] }

Member          :: { AST }
                : Variable_Def                                                { $1 }
                | Function_Def                                                { $1 }
                | Operator_Def                                                { $1 }

Member_Seq      :: { [AST] }
                : ';' Member Member_Seq                                       { $2 : $3 }
                | {- empty -}                                                 { [] }

Mutation        :: { AST }
                : identifier larrow Expression                                { ReAssignment $1 $3 }
                | Object_Field larrow Expression                              { FieldReAssignment $1 $3 }
                | Array_Access larrow Expression                              { ArrayIndexReAssignment $1 $3 }

Accessible      :: { AST }
                : '(' Expression ')'                                          { $2 }
                | Block                                                       { $1 }
                | Application                                                 { $1 }
                | Array_Def                                                   { $1 }
                | Array_Access                                                { $1 }
                | identifier                                                  { Identifier $1 }
                | Literal                                                     { $1 }

Conditional     :: { AST }
                : if Expression then Expression Else_M                        { If $2 $4 $5 }

Else_M          :: { AST }
                : else Expression                                             { $2 }
                | {- empty -}                                                 { Unit }

Loop            :: { AST }
                : while Expression do Expression                              { While $2 $4 }

Block           :: { AST }
                : begin Expression Expression_Seq Semi_M end                  { Block $ $2 : $3 }


Object_Field    :: { AST }
                : Accessible '.' Field_Seq identifier                         { ObjectFieldAccess $1 $3 $4 }

Field_Seq       :: { [AST] }
                : identifier '.' Field_Seq                                    { (Identifier $1) : $3 }
                | {- empty -}                                                 { [] }

Method          :: { AST }
                : Accessible '.' Field_Seq Id_Op                              { Method $1 $3 $4 }

Id_Op           :: { AST }
                : identifier                                                  { Identifier $1 }
                | Operator                                                    { $1 }

Param_List      :: { [AST] }
                : identifier Identifier_Seq Comma_M                           { (Identifier $1) : $2 }
                | {- empty -}                                                 { [] }

Identifier_Seq  :: { [AST] }
                : ',' identifier Identifier_Seq                               { (Identifier $2) : $3 }
                | {- empty -}                                                 { [] }

Comma_M         :: { () }
                : ';'                                                         { () }
                | {- empty -}                                                 { () }

Arg_List        :: { [AST] }
                : Expression Value_Seq Comma_M                                { $1 : $2 }
                | {- empty -}                                                 { [] }

Value_Seq       :: { [AST] }
                : ',' Expression Value_Seq                                    { $2 : $3 }
                | {- empty -}                                                 { [] }

Callable        :: { AST }
                : identifier                                                  { Identifier $1 }
                | Object_Field                                                { $1 }

Application     :: { AST }
                : Callable '(' Arg_List ')'                                   { Application $1 $3 }

Array_Access    :: { AST }
                : Accessible '[' Expression ']'                               { ArrayAccess $1 $3 }
                | Object_Field '[' Expression ']'                             { ArrayAccess $1 $3 }

Prnt_Args       :: { [AST] }
                : ',' Arg_List                                                { $2 }
                | {- empty -}                                                 { [] }

Print           :: { AST }
                : print '(' string Prnt_Args ')'                              { Print $3 $4 }


Operation       :: { AST }
                : Operation Operator Operation                                { Operation $2 $1 $3 }
                | Accessible                                                  { $1  -- Operable - without Array_Def}

{
parserError :: [Token.Token] -> a
parserError _ = error "Parse error"
}