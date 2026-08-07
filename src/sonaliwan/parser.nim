# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import rule
import terminalrules
import nonterminalrules
import regexprules
import std/[re, strutils, sequtils, tables, sets, deques, os, streams]

type
  Parser* = ref object
    nonTerminalRules*: NonTerminalRules
    terminalRules*: TerminalRules
    regexpRules*: RegexpRules
  Box = ref object
    s: seq[string]

proc inclNotIn(h: var HashSet[string], s: string): bool =
  if s notin h:
    h.incl(s)
    return true
  return false

proc newParser*(): Parser =
  Parser(
    nonTerminalRules: newNonTerminalRules(),
    terminalRules: newTerminalRules(),
    regexpRules: newRegexpRules()
  )

proc newParser*(ntr: NonTerminalRules, tr: TerminalRules, rr: RegexpRules): Parser =
  Parser(nonTerminalRules: ntr, terminalRules: tr, regexpRules: rr)

proc newParser*(fileName: string): Parser =
  result = newParser()
  if not fileExists(fileName):
    return
  let f = newFileStream(fileName, fmRead)
  if f.isNil: return
  defer: f.close()
  var line: string
  while f.readLine(line):
    let ruleParts = line.strip.splitWhitespace()
    if ruleParts.len > 2:
      let key = ruleParts[0]
      if key != "#":
        let rhs = ruleParts[2 .. ^1]
        if key == toLowerAscii(key):
          if ruleParts[1].startsWith("R"):
            result.regexpRules.add(key, rhs)
          else:
            result.terminalRules.add(key, rhs)
        else:
          result.nonTerminalRules.add(key, rhs)

proc getValidTerminalRulesForWords*(
    p: Parser,
    words: seq[string]
  ): Table[string, HashSet[string]] =
  var validTerminalRules = initTable[string, HashSet[string]]()
  for word in words.deduplicate():
    var validRules = initHashSet[string]()
    for (k, vals) in p.terminalRules.rules.pairs:
      if word in vals:
        validRules.incl k

    if validRules.len()==0:
      for (k, regs) in p.regexpRules.rules.pairs:
        for r in regs:
          if contains(word, r): # manage a cached regexp registry?
            p.terminalRules.add(k, @[word])
            validRules.incl k
            break

    if validRules.len()>=0:
      validTerminalRules[word] = validRules

  validTerminalRules

proc parse*(p: Parser, key, sentence, startWith: string): seq[string] =
  var processedKeys = initHashSet[string]()
  var results: seq[string] = @[]

  try:
    var fifoKey = initDeque[seq[string]]()
    var fifoValue = initDeque[Rule]()

    var words = sentence.splitWhitespace().filterIt(it.len > 0)

    let validTerminalRules =
      p.getValidTerminalRulesForWords(words)
    let wordsSize = words.len

    var distinctTerminalRules = initHashSet[string]()
    for (_, hs) in validTerminalRules.pairs:
      for v in hs:
        distinctTerminalRules.incl(v)

    p.nonTerminalRules.filter(distinctTerminalRules)

    if p.nonTerminalRules.contains(key):
      for def in p.nonTerminalRules.get(key):
        var decTermsSize = def.terms.len
        var isValid = decTermsSize <= wordsSize
        var i = 0
        while i < decTermsSize and isValid:
          let termsGet = def.terms[i]
          if termsGet == termsGet.toLowerAscii():
            isValid = validTerminalRules[words[i]].contains(termsGet)
            inc i
          else:
            i = decTermsSize
        if isValid:
          fifoKey.addLast(@[key & ":" & $def.id])
          fifoValue.addLast(newRuleWithId(
            def.terms.mapIt(it.replace("#", "")),
            def.id
          ))

      while fifoKey.len > 0 and fifoKey.len < 1_500_000:
        let keys = fifoKey.popFirst()
        let def = fifoValue.popFirst()

        if startWith.len > 0 and def.terms.join(" ").startsWith(startWith):
          echo def.terms

        if def.terms.allIt(it == it.toLowerAscii()):
          # all terminals
          var isValid = def.terms.len == wordsSize
          var i = 0
          while i < wordsSize and isValid:
            isValid = validTerminalRules[words[i]].contains(def.terms[i])
            inc i
          if isValid:
            var res: seq[Box] = @[]
            var exp: seq[string] = @[]
            var rank: int
            for i, k in keys:
              let part = k.split(":")
              let id = parseInt(part[1])
              if i > 0:
                rank = parseInt(part[0])
                exp.delete(rank)
                exp.insert(rule.getRule(id), rank)
                res.add(Box(s:exp))
              else:
                exp = rule.getRule(id)
                res.add(Box(s:exp))

            #var tgt:ptr = addr res[res.len - 1]
            var tgt = res[res.len - 1]
            var frm = words
            for i in 0 ..< wordsSize:
              if tgt.s[i].startsWith("#"):
                tgt.s[i] = frm[i] & "_"
              else:
                let base = if "_" in tgt.s[i]: tgt.s[i].split("_")[0] else: tgt.s[i]
                tgt.s[i] = "(" & base & " " & frm[i] & ")"

            for i in countdown(keys.len - 2, 0):
              let part = keys[i + 1].split(":")
              let id = parseInt(part[1])
              tgt = res[i]
              frm = res[i + 1].s
              rank = parseInt(part[0])
              let size = rule.getRule(id).len

              var j = 0
              while j < tgt.s.len:
                if j == rank:
                  var sub = ""
                  if tgt.s[rank].startsWith("#"):
                    for x in frm[rank ..< rank + size]:
                      sub.add x
                  else:
                    sub.add "(" & tgt.s[rank] & " "
                    for x in frm[rank ..< rank + size]:
                      sub.add x
                    sub.add ")"
                  tgt.s[rank] = sub
                else:
                  if j < rank:
                    tgt.s[j] = frm[j]
                  else:
                    tgt.s[j] = frm[j + size - 1]
                inc j

            var sb = "(" & key & " "
            for t in tgt.s:
              sb.add t
            sb.add ")"
            results.add sb
        else:
          # resolve non-terminals
          let decTermsSize = def.terms.len
          var found = false
          var rank = 0
          while rank < decTermsSize and not found:
            found = p.nonTerminalRules.contains(def.terms[rank])
            if not found: inc rank
          if found:
            for sdf in p.nonTerminalRules.get(def.terms[rank]):
              var updKey = keys
              updKey.add($rank & ":" & $sdf.id)
              var updDef = def.terms
              updDef.delete(rank)
              updDef.insert(
                sdf.terms.mapIt(it.replace("#", "")),
                rank
              )
              let processedKey = updDef.join("")
              if updDef.len <= wordsSize and processedKeys.inclNotIn(processedKey):
                var isValid = true
                var i = 0
                while i < rank and isValid:
                  isValid = validTerminalRules[words[i]].contains(updDef[i])
                  inc i
                i = rank
                while i < updDef.len and isValid and
                      updDef[i] == updDef[i].toLowerAscii():
                  isValid = validTerminalRules[words[i]].contains(updDef[i])
                  inc i
                if isValid:
                  fifoKey.addLast(updKey)
                  if startWith.len > 0 and def.terms.join(" ").startsWith(startWith):
                    echo " → ", updDef
                  fifoValue.addLast(newRuleWithId(updDef, sdf.id))

      if startWith.len > 0:
        echo fifoKey.len
        var cnt = min(fifoKey.len, 10)
        while cnt > 0 and fifoValue.len > 0:
          echo fifoValue.popFirst().terms
          dec cnt

  except CatchableError as e:
    echo e.msg

  results
