# To run these tests, simply execute `nimble test`.

import unittest
import std/os
import sonaliwan/parser

proc tok(): string =
  let p = newParser("tests/grammar-demo.txt")
  let bufferList = p.parse("S", "The cat eats", "")
  if bufferList.len == 1 and bufferList[0].len > 0:
    bufferList[0]
  else:
    "ERROR"

test "parser.parse":
  check tok() == "(S (NP (det The)(n cat))(VP (v eats)))"
