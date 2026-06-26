# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import std/[tables, sequtils]

type
  Rule* = ref object
    terms*: seq[string]
    id*: int

var
  autoinc* = 0
  index*: Table[int, seq[string]] = initTable[int, seq[string]]()

proc newRule*(terms: seq[string]): Rule =
  result = Rule(terms: terms, id: autoinc)
  index[result.id] = result.terms
  inc autoinc

proc newRuleWithId*(terms: seq[string], id: int): Rule =
  Rule(terms: terms, id: id)

proc getRule*(id: int): seq[string] =
  ## Returns a copy of the stored terms
  index[id].toSeq
