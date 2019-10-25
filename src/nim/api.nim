import jester
import json
import strutils
import re
import random
import sequtils
import sugar
import db_sqlite

import verbly_db

randomize()

type
    Option = tuple
        subject: string
        index: int
        engSub: string

proc pick3(subjList: seq[Option]): seq[Option] =
    var rand: Option
    result = @[]
    for i in 0..<3:
        rand = sample(subjList)
        while result.any((x) => x.index == rand.index):
            rand = sample(subjList)
        result.add(rand)

proc getVerbData(db: DbConn, data: tuple[vid: int, verb: string]): JsonNode =
    result = newJObject()
    var conjs = db.getVerbConjugations(data.vid)
    var conjAry = newJArray()
    for conj in conjs:
        conjAry.add(newJString(conj.replace("\"", "")))
    result.add(data.verb, conjAry)

routes:
    get "/verbs":
        var ret = newJArray()
        withSqliteDb(db):
            for verb in db.getAllVerbs():
                ret.add(getVerbData(db, verb))
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)

    get "/verbs/@verb":
        var verb = (@"verb").replace("%20", " ")
        var ret = newJArray()
        withSqliteDb(db):
            let partialMatches = db.matchEnglishVerb(verb)
            for match in partialMatches:
                ret.add(getVerbData(db, match))
        if ret.len > 0:
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verbs/conjugation/@conj":
        var conj = (@"conj").replace("%20", " ")
        var ret = newJArray()
        withSqliteDb(db):
            let match = db.getVerbByConjugation(conj)
            if match.vid != -1:
                ret.add(getVerbData(db, match))
        if ret.len > 0:
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verb/random":
        var
            subject: string
            engSub: string
            options: seq[string]
            verb: string
            verbData: JsonNode
        withSqliteDb(db):
            verbData = getVerbData(db, db.getRandomVerb())
        let subjects = @[   # Map subjects to the index of their conjugation
            ("Io", 0, "I"),
            ("Tu", 1, "You"),
            ("Lui", 2, "He"),
            ("Lei", 2, "She"),
            ("Noi", 3, "We"),
            ("Voi", 4, "You"),
            ("Loro", 5, "They")
        ]
        var picked = subjects.pick3
        for pick in picked:
            # can't do .keys() unpacking, so 1-item loops ftw   :(
            for key in verbData.keys():
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
        var right = options[2] # last option will always be the "right" one
        shuffle(options) # let's not make "C" the right answer every time.
        var outData = %*{
            "verb": verb,
            "subject": subject,
            "englishSubject": engSub,
            "right": right,
            "rightIndex": options.find(right),
            "options": options
        }
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, outData.pretty)
