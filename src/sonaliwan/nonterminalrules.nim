# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import std/[strutils, tables, sequtils, sets]
import rule

type
  NonTerminalRules* = ref object
    rules*: Table[string, seq[Rule]]
    filteredRules*: Table[string, seq[Rule]]

proc newNonTerminalRules*(): NonTerminalRules =
  NonTerminalRules(
    rules: initTable[string, seq[Rule]](),
    filteredRules: initTable[string, seq[Rule]]()
  )

proc newNonTerminalRules*(rules: Table[string, seq[Rule]]): NonTerminalRules =
  NonTerminalRules(rules: rules, filteredRules: rules)

proc add*(ntr: NonTerminalRules, key: string, value: seq[string]) =
  var defs = ntr.rules.getOrDefault(key, @[])
  defs.add newRule(value)
  ntr.rules[key] = defs

proc get*(ntr: NonTerminalRules, key: string): seq[Rule] =
  ntr.filteredRules.getOrDefault(key, @[])

proc contains*(ntr: NonTerminalRules, key: string): bool =
  ntr.filteredRules.hasKey(key)

proc filter*(ntr: NonTerminalRules, filterSet: HashSet[string]) =
  ntr.filteredRules = initTable[string, seq[Rule]]()
  for (k, rulesSeq) in ntr.rules.pairs:
    for r in rulesSeq:
      # keep rule if no lowercase term is outside filterSet (after removing '#')
      let keep = r.terms.all(proc(t: string): bool =
        if t == toLowerAscii(t):
          filterSet.contains(t.replace("#", ""))
        else:
          true
      )
      if keep:
        var defs = ntr.filteredRules.getOrDefault(k, @[])
        defs.add newRule(r.terms) # copy
        ntr.filteredRules[k] = defs
