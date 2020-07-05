import Test.Hspec
import Control.Exception (evaluate)

import qualified ScannerSpec
import qualified ParserSpec
import qualified InterpreterSpec

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "Basic Scanner Test" ScannerSpec.spec
  describe "Basic Parser Test" ParserSpec.spec
  describe "Basic AST Intepreter Test" InterpreterSpec.spec