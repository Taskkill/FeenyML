module VM.Stack where

-- https://en.wikipedia.org/wiki/Stack_(abstract_data_type)
data Stack a = Empty | NonEmpty a (Stack a)
             deriving (Show, Read, Eq)

empty :: Stack a
empty = Empty

-- Get element from top of stack
-- If stack is empty error with message "Empty stack" will be raised
top :: Stack a -> a
top (NonEmpty a _) = a
top Empty = error "Empty stack"

-- Get element from top of stack (if there is some, otherwise return Nothing)
topSafe :: Stack a -> Maybe a
topSafe Empty = Nothing
topSafe (NonEmpty a _) = Just a

popN :: Integral a => a -> Stack b -> ([b], Stack b)
popN 0 stack = ([], stack)
popN n stack =
  let
    c = top stack 
    (l, s) = popN (n - 1) $ pop stack
  in
    (c : l, s)

-- Pop element from top of stack
-- If stack is empty error with message "Empty stack" will be raised
pop :: Stack a -> Stack a
pop (NonEmpty _ stack) = stack
pop Empty = error "Empty stack"

-- Pop element from top of stack (if there is some, otherwise return Nothing)
popSafe :: Stack a -> Maybe (Stack a)
popSafe (NonEmpty _ stack) = Just stack
popSafe Empty = Nothing

-- Push element to top of stack
push :: a -> Stack a -> Stack a
push e stack = NonEmpty e stack

-- Get number of elements in stack
size :: Num n => Stack a -> n
size Empty = 0
size (NonEmpty _ stack) = 1 + size stack

-- Check if stack is empty
-- Note: is more effective than checking if size is zero
null :: Stack a -> Bool
null Empty = True
null (NonEmpty _ _) = False
