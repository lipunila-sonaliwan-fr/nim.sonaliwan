# To run these tests, simply execute `nimble test`.

import unittest
import sonaliwan/parser

proc tok(): seq[string] =
  let p = newParser("tests/grammar-test3.txt")
  let bufferList = p.parse("S", "mi moku pona", "")
  if bufferList.len >= 1 and bufferList[0].len > 0:
    echo p.getWeight(bufferList)
    p.getWeight(bufferList)
  else:
    @["ERROR"]

test "newParser(\"tests/grammar-test3.txt\") ... p.getWeight(...)":
  check tok() == @[
    "2\t→ (S (NP (proper mi))(VP (v moku)(ADJ (adj pona))))",
    "1\t  (S (NP (proper mi))(VP (ADJ (adj moku)(adj pona))))"    
  ]
