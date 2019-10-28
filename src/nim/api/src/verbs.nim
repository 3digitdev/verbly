import json
import strutils
import random
import sequtils
import sugar
import db_sqlite

# database
import verbly_db
# extras
import helpers

randomize()

type
    Option = tuple
        subject: string
        index: int
        engSub: string

const SUBJECTS = @[   # Map subjects to the index of their conjugation
    ("Io", 0, "I"),
    ("Tu", 1, "You"),
    ("Lui", 2, "He"),
    ("Lei", 2, "She"),
    ("Noi", 3, "We"),
    ("Voi", 4, "You"),
    ("Loro", 5, "They")
]

#---  /verbs  ---#
proc getAllVerbs*(): JsonNode =
    result = newJArray()
    withSqliteDb(db):
        for verb in db.getAllVerbs():
            result.add(getVerbData(db, verb))

proc getVerbByName*(name: string): JsonNode =
    result = newJArray()
    withSqliteDb(db):
        for match in db.matchEnglishVerb(name):
            result.add(getVerbData(db, match))

proc getVerbByConjugation*(conj: string): JsonNode =
    result = newJArray()
    withSqliteDb(db):
        let match = db.getVerbByConjugation(conj)
        if match.vid != -1:
            result.add(getVerbData(db, match))

#---  /verb   ---#
proc pick3(subjList: seq[Option]): seq[Option] =
    var rand: Option
    result = @[]
    for i in 0..<3:
        rand = sample(subjList)
        while result.any((x) => x.index == rand.index):
            rand = sample(subjList)
        result.add(rand)

proc getRandomVerb*(): JsonNode =
    var
        subject, engSub, verb: string
        options: seq[string]
        verbData: JsonNode
    withSqliteDb(db):
        verbData = getVerbData(db, db.getRandomVerb())
    let picked = SUBJECTS.pick3
    for pick in picked:
        # can't do .keys() unpacking, so 1-item loops ftw   :(
        for key in verbData.keys():
            # in the end of this loop, these 3 vars will each hold the last item's data
            verb = key.split(";")[0] # Only take 1 of the definitions
            subject = pick.subject
            engSub = pick.engSub
            # We want to make it look good grammatically, so let's add "s" to
            # the first word of the verb definition for he/she
            if engSub == "He" or engSub == "She":
                var split = verb.split(" ")
                if split[0][^1] == 's':
                    split[0] &= "(es)"
                else:
                    split[0] &= "(s)"
                verb = split.join(" ")
            options.add(verbData[key].getElems[pick.index].getStr)
    var right = options[2] # last option will always be the "correct" one...
    shuffle(options) # ...but let's not make "C" the correct answer every time.
    result = %*{
        "verb": verb,
        "subject": subject,
        "englishSubject": engSub,
        "right": right,
        "rightIndex": options.find(right),
        "options": options
    }
