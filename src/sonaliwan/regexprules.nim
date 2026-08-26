# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import std/[tables, re]

type
  RegexpRules* = ref object
    rules*: Table[string, seq[Regex]]

proc newRegexpRules*(): RegexpRules =
  RegexpRules(rules: initTable[string, seq[Regex]]())

proc add*(tr: RegexpRules, key: string, value: seq[string]) =
  var terms = tr.rules.getOrDefault(key, @[])
  for term in value:
    let r = rex(term)
    if r notin terms:
      terms.add r
  tr.rules[key] = terms

proc contains*(tr: RegexpRules, key: string): bool =
  tr.rules.hasKey(key)

proc get*(tr: RegexpRules, key: string): seq[Regex] =
  tr.rules.getOrDefault(key, @[])
