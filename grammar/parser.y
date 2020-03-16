{
  module Main where
}

%name program
%tokentype { Token }
%error { parserError }

%token
{-            '_'           { Underscore } -}
              '('           { LeftParen }
              ')'           { RightParen }
              '['           { LeftBracket }
              ']'           { RightBracket }
              ';'           { Semicolon }
              '.'           { Dot }
              ','           { Comma }
              larrow        { LeftArrow }
              rarrow        { RightArrow }
              '='           { Be }

              '+'           { Plus }
              '-'           { Minus }
              '*'           { Multiply }
              '/'           { Divide }
              '%'           { Modulo }
              leq           { LesserEqual }
              greq          { GreaterEqual }
              '<'           { Lesser }
              '>'           { Greater }
              '|'           { Or }
              '&'           { And }
              eq            { Equal }
              uneq          { UnEqual }

              while         { While }
              object        { Object }
              if            { If }
              else          { Else }
              then          { Then }
              true          { True }
              false         { False }
              array         { Array }
              unit          { Unit }
              let           { Let }
              begin         { Begin }
              end           { End }
              this          { This }
              print         { Print }
              function      { Function }
              do            { Do }
              extends       { Extends }

              identifier    { Identifier $$ }
              number        { Number $$ }
              string        { String $$ }

%nonassoc '>' '<' eq uneq leq greq
%left '|' '&'
%left '-' '+'
%left '*' '/' '%'
%%

TopLevel    : Expression Semi_M                     { $1 -- ';' }
            | Expression Expression_Seq Semi_M      { $1 : $2 -- ';' }
            | {- empty -}                           { [] }


Expression_Seq
            : ';' Expression Expression_Seq         { $2 : $3 }
            | {- empty -}                           { [] }

Semi_M      : ';'                                   { () }
            | {- empty -}                           { () }


Operator    : '*'                                   { Multiply }
            | '+'                                   { Plus }
            | '-'                                   { Minus }
            | '/'                                   { Divide }
            | '%'                                   { Modulo }
            | uneq                                  { UnEqual }
            | eq                                    { Equal }
            | '<'                                   { Lesser }
            | '>'                                   { Greater }
            | leq                                   { LesserEqual }
            | greq                                  { GreaterEqual }
            | '&'                                   { And }
            | '|'                                   { Or }

Literal     : number                                { Number $1 }
            | false                                 { Boolean $1 }
            | true                                  { Boolean $1 }
            | unit                                  { Unit }
            | begin end                             { Unit }

Expression  : Function_Def                          { $1 }
            | Object_Def                            { $1 }
            | Variable_Def                          { $1 }
            | Object_Field                          { $1 }
            | Conditional                           { $1 }
            | Loop                                  { $1 }
            | Mutation                              { $1 }
            | Print                                 { $1 }
            | Operation                             { $1 }

Function_Def
            : function identifier '(' Param_List ')' rarrow Expression    { FucntionDef $2 $4 $7 }

Variable_Def
            : let identifier '=' Expression                               { Let $2 $4 }

Array_Def   : array '(' Expression '.' Expression ')'                     { Array $2 $4 }

Operator_Def
            : function Operator '(' Param_List ')' rarrow Expression      { OperatorDef $2 $4 $7 }

Extends     : extends Expression                                          { Extends $2 }

Object_Def  : object Param_List Extends begin Object_Body end             { ObjectDef $3 $2 $5 }

Object_Body : Member Semi_M                                               { $1 }
            | Member Member_Seq Semi_M                                    { $1 : $2 }
            | {- empty -}                                                 { [] }

Member      : Variable_Def                                                { $1 }
            | Function_Def                                                { $1 }
            | Operator_Def                                                { $1 }

Member_Seq  : ';' Member Member_Seq                                       { $2 ++ $3 }
            | {- empty -}                                                 { [] }

Mutation    : identifier larrow Expression                                { ReAssignment $1 $3 }
            | Object_Field larrow Expression                              { FieldReAssignment $1 $3 }
            | Array_Access larrow Expression                              { ArrayIndexReAssignment $1 $3 }

Accessible  : '(' Expression ')'                                          { $2 }
            | Block                                                       { $1 }
            | Application                                                 { $1 }
            | Array_Def                                                   { $1 }
            | Array_Access                                                { $1 }
            | identifier                                                  { Identifier $1 }
            | Literal                                                     { $1 }

Conditional : if Expression then Expression Else_M                        { If $2 $4 $5 }

Else_M      : else Expression                                             { $1 }
            | {- empty -}                                                 { Null }

Loop        : while Expression do Expression                              { While $2 $4 }

Block       : begin Expression Expression_Seq end                         { $2 : $3 }


Object_Field
            : Accessible '.' Field_Seq identifier                         { ObjectFieldAccess $1 $3 $4 }

Field_Seq   : identifier '.' Field_Seq                                    { $1 : $3 }
            | {- empty -}                                                 { [] }

Method      : Accessible '.' Field_Seq Id_Op                              { Method $1 $3 $4 }

Id_Op       : identifier                                                  { Identifier $1 }
            | Operator                                                    { $1 }

Param_List  : identifier Identifier_Seq Comma_M                           { (Identifier $1) : $2 }
            | {- empty -}                                                 { [] }

Identifier_Seq
            : ',' identifier Identifier_Seq                               { (Identifier $2) : $3 }
            | {- empty -}                                                 { [] }

Comma_M     : ';'                                                         { () }
            | {- empty -}                                                 { () }

Arg_List    : Expression Value_Seq Comma_M                                { $1 : $2 }
            | {- empty -}                                                 { [] }

Value_Seq   : ',' Expression Value_Seq                                    { $2 : $3 }
            | {- empty -}                                                 { [] }

Callable    : identifier                                                  { Identifier $1 }
            | Object_Field                                                { $1 }
            | array                                                       { Array $1 }

Application : Callable '(' Arg_List ')'                                   { Application $1 $3 }

Array_Access
            : Accessible '[' Expression ']'                               { ArrayAccess $1 $3 }
            | Object_Field '[' Expression ']'                             { ArrayAccess $1 $3 }

Prnt_Args   : ',' Arg_List                                                { $2 }
            | {- empty -}                                                 { [] }

Print       : print '(' string Prnt_Args ')'                              { Print $2 $3 }



Operation   : Operation Operator Operation                                { Operation $2 $1 $3 }
            | Accessible                                                  { $1  -- Operable - without Array_Def}
