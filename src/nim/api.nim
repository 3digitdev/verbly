import jester
import json
import strformat
import strutils
import re
import random
import sequtils
import sugar

const VERBFILE = "../../data/verbs.json"
randomize()

type
    Option = tuple[subject: string, index: int, engSub: string]

proc pick3(subjList: seq[Option]): seq[Option] =
    var rand: Option
    result = @[]
    for i in 0..<3:
        rand = sample(subjList)
        while result.any((x) => x.index == rand.index):
            rand = sample(subjList)
        result.add(rand)


routes:
    get "/verbs":
        let jdata = parseFile(VERBFILE)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, jdata.pretty)

    get "/verbs/@verb":
        var verb = (@"verb").replace("%20", " ")
        let jdata = parseFile(VERBFILE)
        var ret = newJArray()
        var rx = re(&"(?<!\\w){verb}(?:;|(?!\\w))")
        for verbObj in jdata.getElems:
            for key in verbObj.keys:
                if key.find(rx) >= 0:
                    var json = &"""{{"{key}": {verbObj[key]}}}"""
                    ret.add(parseJson(json))
        if ret.len > 0:
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verbs/conjugation/@conj":
        let jdata = parseFile(VERBFILE)
        for k, v in jdata.pairs():
            if v.contains(newJString(@"conj")):
                resp(Http200, {"Access-Control-Allow-Origin":"*"}, (%*{ k: v }).pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verb/random":
        var
            subject: string
            engSub: string
            options: seq[string]
            verb: string
            next: tuple[subject: string, conjugation: string]
        let jdata = parseFile(VERBFILE)
        let verbData = sample(jdata.getElems)
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
