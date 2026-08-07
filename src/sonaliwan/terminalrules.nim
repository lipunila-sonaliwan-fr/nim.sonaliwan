# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import std/tables

type
  TerminalRules* = ref object
    rules*: Table[string, seq[string]]

proc newTerminalRules*(): TerminalRules =
  TerminalRules(rules: initTable[string, seq[string]]())

proc add*(tr: TerminalRules, key: string, value: seq[string]) =
  var terms = tr.rules.getOrDefault(key, @[])
  for term in value:
    if term notin terms:
      terms.add term
  tr.rules[key] = terms

proc contains*(tr: TerminalRules, key: string): bool =
  tr.rules.hasKey(key)

proc get*(tr: TerminalRules, key: string): seq[string] =
  tr.rules.getOrDefault(key, @[])
