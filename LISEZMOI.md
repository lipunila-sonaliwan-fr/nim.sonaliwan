```
   _._
 o|- -|o This file is licensed under CC BY-NC-SA 4.0 international license.
  ( l )  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
    =    Author: jean-marc "jihem" quere 2016
```

## parser 
> Lab'Oratoire / Projet magenta - Laboratoire de Psycholinguistique Cognitive et Sociale \
> https://lipunila.sonaliwan.fr - metalab(at)sonaliwan.fr

**sonaliwan/parser** est un analyseur syntaxique léger qui vérifie si une chaîne de symboles est conforme à une grammaire formelle \
et en construit l'arbre d'analyse. Il prend en entrée un fichier de règles (utilisant un format simplifié proche de la notation BNF) et produit \
une représentation structurée du texte analysé, utile pour l'interprétation, la validation ou la transformation de données. \
Ce projet s'inscrit dans le cadre du Lab'Oratoire / Projet Magenta (Laboratoire de psycholinguistique cognitive et sociale) \
et comprend un moteur d'analyse extensible compatible avec des grammaires personnalisées.

La *grammaire formelle* définit les règles (voir [grammar.txt]) :
- quelles chaînes sont valides ;
- comment elles peuvent être organisées ;
- comment les symboles se combinent.

Les règles s'expriment sous la forme : "Symbole → Terme Terme... Terme". Le signe "→" occupe la seconde position sur la \
ligne et peut-être remplacé par une suite de caractères quelconque ne comprenant pas d'espace, ex. : "->", \
":", "=", "comporte", etc. Les symboles et termes ne peuvent pas comporter d'espace. Un Terme est *terminal* (symbole final qui ne peut plus \
être remplacé) ou *non-terminal* (symbole intermédiaire défini par une règle). Les règles associées sont donc \
terminales (Symbole écrit en miniscule → Terme Terme... Terme) ou non-terminales (Symbole comportant au moins \
une majuscule → Terme Terme... Terme).

Exemple :

grammar-demo.txt
```
S → NP VP
NP → det n
VP → v
det → Le le
n → chat
v → mange
```

Le programme ci-dessous analyse la phrase "Le chat mange". La règle "S" correspond à la nature de l'entité à analyser : \
une phrase.
```
import sonaliwan/parser
let p = newParser("grammar-demo.txt")
let bufferList = parse(p, "S", "The cat eats", "")
for str in bufferList:
  echo(str)
```
Il affiche "(S (NP (det Le)(n chat))(VP (v mange)))".
La phrase est donc correcte et correspond à l'arbre syntaxique suivant :

```
       S
     /   \
   NP     VP
  /  \     \
det   n     v
Le    chat  mange
```

Lorsque le ArrayList<String> renvoyé est vide ou ne comporte qu'une seule chaîne vide, la phrase est incorrecte.
```
if bufferList.len == 0 or (bufferList.len == 1 and bufferList[0].len == 0):
  echo("Incorrect expression.")
```

Les lignes du fichier comportant la grammaire débuttant par un caractère "#" sont des commentaires (et sont ignorées). \
Les symboles non-terminaux précédés par "#" dans une règle n'apparaissent pas dans le résultat renvoyé, ex. \
en remplaçant "NP → det n" par "NP → #det #n" (dans grammar-demo.txt) :
```
(S (NP Le_chat_)(VP (v mange)))
```
Le groupe nominal (Noun Phrase) n'est pas détaillé.

Le caractère "_" dans un symbole, permet de renvoyer l'indication d'une règle spécifique (ex. n_chat, v_miaule) sous \
une forme générique (n, v). La grammaire suivante permet de vérifier que :
- (S (det Le)(n chat))(v mange))
- (S (det Le)(n chat)(v miaule))
- mais n'aboie pas.

```
S → det n_chat v_miaule
S → det n_chien v_aboie
S → det #N v
det → Le le
N → n_chat
N → n_chien
n_chat → chat
n_chien → chien
v → mange
v_miaule → miaule
v_aboie → aboie
```

Pour faciliter la rédaction de la grammaire, il est possible de consulter les règles induites à partir d'un stade \
d'analyse choisi (à préciser en dernier argument, ex. "det", "det N", etc.

```
let bufferList = parse(p, "S", "The cat eats", "det")
```

"S → det #N v" devient "det, n_chat, v" (grâce à "N → n_chat") et permet de valider la phrase car "n_chat → chat". \
La derniere valeur indiquée précise de nombre de règles non traitées en cas d'abandon (1500000 par défaut, voir \
#89 de parser.nim).

```
[det, N, v]
→ [det, n_chat, v]
[det, n_chat, v]
0
```
