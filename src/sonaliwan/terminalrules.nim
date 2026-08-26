# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import std/tables
import term

type
  TerminalRules* = ref object
    rules*: Table[string, seq[Term]]

proc newTerminalRules*(): TerminalRules =
  TerminalRules(rules: initTable[string, seq[Term]]())

proc add*(tr: TerminalRules, key: string, spellings: seq[string], weight: int) =
  var terms = tr.rules.getOrDefault(key, @[]) # ***
  var spellingOfTerms = terms.getSpellingOfTerms()
  for spelling in spellings:
    if spelling notin spellingOfTerms:
      terms.add newTerm(spelling, weight)
  tr.rules[key] = terms

proc contains*(tr: TerminalRules, key: string): bool =
  tr.rules.hasKey(key)

proc get*(tr: TerminalRules, key: string): seq[Term] =
  tr.rules.getOrDefault(key, @[])
