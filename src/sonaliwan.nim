# nim c -r -d:release sonaliwan.nim
# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

import std/[os, strutils, streams, times]
import sonaliwan/parser

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
  var stdoutEcho  = false
  var showWeight  = false
  var startWith   = ""
  var err = false
  var lineCount = 0
  var errorCount = 0

  for arg in commandLineParams():
    if arg.startsWith("-"):
      let parts = arg[1 .. ^1].split("=", maxsplit = 1)
      if parts.len > 1 and parts[1].len>0:
        case parts[0]
        of "i": inputFile = parts[1]
        of "o": outputFile = parts[1]
        of "g": grammarFile = parts[1]
        of "d": startWith = parts[1].replace("-", " ")
        else: err = true
      else:
        case parts[0]
        of "c": stdoutEcho = true
        of "w": showWeight = true
        else: err = true

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
    var writeBuf: string
    while inStream.readLine(sentence):
      sentence = cleanSentence(sentence)

      if sentence.len > 0 and not sentence.startsWith("#"):
        try:
          inc lineCount
          writeBuf = "\t" & sentence
          if stdoutEcho:
            echo(writeBuf)
          writeBuf.add("\n")

          let bufferList = parse(p, "S", sentence, startWith)

          if bufferList.len == 0 or (bufferList.len == 1 and bufferList[0].len == 0):
            inc errorCount
          else:
            var log: string
            if showWeight:
              for ind, str in p.getWeight(bufferList):
                log = $lineCount & "." & $(ind+1) & "\t" & str
                if stdoutEcho:
                  echo(log)
                writeBuf.add(log & "\n")
            else:
              for ind, str in bufferList:
                log = $lineCount & "." & $(ind+1) & "\t" & str
                if stdoutEcho:
                  echo(log)
                writeBuf.add(log & "\n")

        except CatchableError:
          inc errorCount
          writeBuf.add("???\n")

        outStream.write(writeBuf)
        writeBuf=""

      else:
        sentence = "\t" & sentence
        if stdoutEcho:
          echo(sentence)
        outStream.write(sentence & "\n")

    outStream.write(
      "\n--\nEC / LC = " &
      $errorCount & " / " & $lineCount & "\n--\n"
    )

    let duration = (getTime() - start).inMilliseconds().float
    echo $lineCount, " line(s) processed in : ", duration, " ms (", $errorCount, " error(s)) → ", outputFile
  else:
    echo """
Usage: sonaliwan -i=input.txt -o=output.txt -g=grammar.txt [-d=term-term-...t] [-c] [-w]
  -c : console log on, off by default
  -w : weight inserted for each result
Lab'Oratoire / Projet magenta - Laboratoire de Psycholinguistique Cognitive et Sociale
https://lipunila.sonaliwan.fr - mailto:metalab@sonaliwan.fr
"""

when isMainModule:
  main()
