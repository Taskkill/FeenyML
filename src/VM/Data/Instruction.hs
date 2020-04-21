module VM.Data.Instruction where


data Instruction
  = Lit Int -- retrieve Int or Null from const-pool and push it to the Stack
  | Array -- pop initvalue from the Stack; pop length from the Stack; creates Array object and pushes it to the Stack
  | Print String Int -- format and number of arguments - pop them and execute print -- push Null on the Stack
  | SetLocal Int -- set i'th in the current local frame to the value from the Stack's top
  | GetLocal Int -- push the i'th value from the local frame to the Stack
  | SetGlobal Int -- set the global variable with name specified by i'th String value to top Stack value
  | GetGlobal Int -- retrieve the global variable specified by i'th String name and push it to the Stack
  -- | SetIn Int Int -- first argument indexes to the upper Frames
  -- | GetIn Int Int -- same ^^^
  
  | Drop -- drop one value from operand Stack

  | Object Int -- get Class object at index i; pop N values from the Stack (Object variables), pop parent Object, Object is then pushed on the Stack
  | GetSlot Int -- pop Object from the Stack, get named member value specified by the string on the i'th index (from const-pool???)
  | SetSlot Int -- pop value to store into Object, pop Object from the Stack, same logic as above - stores x?? to the Stack
  -- here is the problem though: if I modify the Object I need another instruction for the machine - which will tell me to replace
  -- old Object in the `memory` with the mutated value
  -- | ReplaceObject Int -- this pops the mutated version of the Object from the Stack
  -- now the index is just taken from the Object - which identifies where in the corresponding Frame, the Object is stored
  | CallSlot Int Int -- pop second number's arguments from Stack, pop the reciever Object from the Stack, method name is specified by i'th index

  | Label Int -- names the current instruction -- name is in i'th slot
  | Branch Int -- pop value from Stack, if value not Null, then sets the instruction pointer to the i'th label
  | Goto Int -- set instruction pointer to the i'th label name
  | Return -- set Parent Frame as current Frame, also set instruction pointer to the `caller` instruction I think
  | Call Int Int -- function name by i'th String and number of arguments by N

  | EOP -- Special instruction meaning - End Of Program -- can only happen once and exactly at the end of the program