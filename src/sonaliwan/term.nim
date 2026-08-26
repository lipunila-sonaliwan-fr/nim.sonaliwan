# CC BY-NC-SA 4.0 - jean-marc "jihem" quere 2016

type
  Term* = ref object
    spelling*: string
    weight*: int

proc newTerm*(spelling: string, weight: int): Term =
  result = Term(spelling: spelling, weight: weight)

proc getSpellingOfTerms*(terms: seq[Term]): seq[string] =
  result = @[]
  for term in terms:
    result.add(term.spelling)

proc getWeightOfTerm*(terms: seq[Term], spelling: string): int =
  result = -1
  for term in terms:
    if term.spelling == spelling:
      result = term.weight
