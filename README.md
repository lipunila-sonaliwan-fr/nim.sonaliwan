```
   _._
 o|- -|o This file is licensed under CC BY-NC-SA 4.0 international license.
  ( l )  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
    =    Author: jean-marc "jihem" quere 2016
```

## parser
> Lab'Oratoire / Project magenta – Laboratory of Cognitive and Social Psycholinguistics
> https://lipunila.sonaliwan.fr – metalab(at)sonaliwan.fr (french)

**sonaliwan/parser** is a lightweight parser that checks whether a string of symbols conforms to a formal grammar \
and constructs its parse tree. It takes a rules file (using a simplified BNF-like format) as input and produces \
a structured representation of the parsed text, which is useful for data interpretation, validation, \
or transformation.
The project is part of the Lab'Oratoire / Projet Magenta (Laboratory of Cognitive and Social Psycholinguistics) \
and includes an extensible parsing engine compatible with custom grammars.

The *formal grammar* defines the rules (see grammar.txt):
- which strings are valid;
- how they may be organized;
- how symbols combine.

Rules are expressed in the form: “Symbol → Term Term … Term”. The “→” sign appears in the second position on the \
line and may be replaced by any sequence of characters that does not contain a space, e.g. “->”, “:”, “=”, \
“comporte”, etc. Symbols and terms cannot contain spaces. A Term is *terminal* (a final symbol that cannot be replaced) \
or *non‑terminal* (an intermediate symbol defined by a rule). The associated rules are therefore: *terminal* \
(symbol written in lowercase → Term Term … Term), or *non‑terminal* (symbol containing at least one uppercase \
letter → Term Term … Term).

Example:
grammar-demo.txt
```
S → NP VP
NP → det n
VP → v
det → The the
n → cat
v → eats
```

The program below parses the sentence “The cat eats”. The rule "S" corresponds to the nature of the entity to be \
analyzed: a sentence.
```
import sonaliwan.parser
let p = newParser("grammar-demo.txt")
let bufferList = parse(p, "S", "The cat eats", "")
for str in bufferList:
  echo(str)
```
It prints: : "(S (NP (det The)(n cat))(VP (v eats)))".
The sentence is therefore correct and corresponds to the following syntax tree:

```
       S
     /   \
   NP     VP
  /  \     \
det   n     v
The   cat   eats
```

When the returned ArrayList<String> is empty or contains only a single empty string, the sentence is incorrect.
```
if bufferList.len == 0 or (bufferList.len == 1 and bufferList[0].len == 0):
  echo("Incorrect expression.")
```

Lines in the grammar file beginning with “#” are comments (and are ignored).
Non‑terminal symbols preceded by “#” in a rule do not appear in the returned result, e.g. replacing
“NP → det n” with “NP → #det #n” (in grammar-demo.txt):
```
(S (NP The_cat_)(VP (v eats)))
```
The noun phrase is not expanded.

The “_” character in a symbol allows returning a specific rule indication (e.g. n_chat, v_miaule) in a generic \
form (n, v). The following grammar allows checking that:
- (S (det The)(n cat))(v eats))
- (S (det The)(n cat)(v meows))
- but not “barks”.

```
S → det n_cat v_meows
S → det n_dog v_barks
S → det #N v
det → The the
N → n_cat
N → n_dog
n_cat → cat
n_dog → dog
v → ears
v_meows → meows
v_barks → barks
```

To make grammar writing easier, it is possible to inspect the rules induced from a chosen analysis stage \
(specified as the last argument, e.g. “det”, “det N”, etc.):

```
let bufferList = parse(p, "S", "The cat eats", "det")
```

“S → det #N v” becomes “det, n_chat, v” (thanks to “N → n_chat”) and validates the sentence because “n_chat → chat”.
The last value indicates the number of unprocessed rules in case of abandonment (1,500,000 by default, see #89 in \
parser.nim).

```
[det, N, v]
→ [det, n_cat, v]
[det, n_cat, v]
0
```
