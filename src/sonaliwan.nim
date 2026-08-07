# nim c -r -d:release sonaliwan.nim
# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016 (original Java version)

import sonaliwan/parser
import std/[os, times, strutils, sequtils, streams]

proc cleanSentence(s: string): string =
  result = s
  for ch in ['.', ',', '?', '!']:
    result = result.replace($ch, " ")
  result = result.replace("ni:", "ni :").strip

proc main() =
  let start = getTime()

  var grammarFile = "grammar.txt"
  var inputFile   = "input.txt"
  var outputFile  = "output.txt"
  var startWith   = ""
  var err = false
  var lineCount = 0
  var errorCount = 0

  for arg in commandLineParams():
    if arg.startsWith("-"):
      let parts = arg[1 .. ^1].split("=", maxsplit = 1)
      if parts.len > 1:
        case parts[0]
        of "i": inputFile = parts[1]
        of "o": outputFile = parts[1]
        of "g": grammarFile = parts[1]
        of "d": startWith = parts[1].replace("-", " ")
        else: discard
      else:
        err = true

  if not err:
    if not fileExists(grammarFile) or not fileExists(inputFile):
      err = true

  if not err:
    let p = newParser(grammarFile)

    if fileExists(outputFile):
      removeFile(outputFile)

    let inStream = newFileStream(inputFile, fmRead)
    if inStream.isNil:
      quit "Cannot open input file"
    defer: inStream.close()

    var outStream = newFileStream(outputFile, fmAppend)
    if outStream.isNil:
      quit "Cannot open output file"
    defer: outStream.close()

    var sentence: string
    while inStream.readLine(sentence):
      sentence = cleanSentence(sentence)
      var writeBuf = sentence & "\n"

      if sentence.len > 0 and not sentence.startsWith("#"):
        try:
          inc lineCount
          let bufferList = parse(p, "S", sentence, startWith)

          if bufferList.len == 0 or (bufferList.len == 1 and bufferList[0].len == 0):
            inc errorCount

          var bestranking = 0
          var besttree: seq[string] = @[]
          for str in bufferList:
            let ranking = str.split("(").filterIt(it.len>0).mapIt(it.split(" ")[0]).deduplicate().len
            if ranking > bestranking:
              bestranking = ranking
              besttree = @[str]
            elif ranking == bestranking:
              besttree.add(str)

          for str in bufferList:
            if str in besttree:
              writeBuf.add("→" & str & "\n")
            else:
              writeBuf.add(" " & str & "\n")

        except CatchableError:
          inc errorCount
          writeBuf.add("???\n")

        var text = writeBuf & "\n"
        text = $lineCount & " " & text
        outStream.write(text)

    outStream.write(
      "--\nEC / LC = " &
      $errorCount & " / " & $lineCount & "\n--\n"
    )

    let duration = (getTime() - start).inMilliseconds().float
    echo $lineCount, " line(s) processed in : ", duration, " ms (", $errorCount, " error(s)) → ", outputFile
  else:
    echo """
Usage: sonaliwan -i=input.txt -o=output.txt -g=grammar.txt [-d=term-term-...t]
Lab'Oratoire / Projet magenta - Laboratoire de Psycholinguistique Cognitive et Sociale
https://lipunila.sonaliwan.fr - mailto:metalab@sonaliwan.fr
"""

when isMainModule:
  main()
