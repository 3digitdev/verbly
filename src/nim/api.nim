import jester
import json
import strformat
import strutils
import re
import random

const VERBFILE = "../../data/verbs.json"
randomize()

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

    get "/base/@conj":
        let jdata = parseFile(VERBFILE)
        for k, v in jdata.pairs():
            if v.contains(newJString(@"conj")):
                resp(Http200, {"Access-Control-Allow-Origin":"*"}, (%*{ k: v }).pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verb/random":
        let jdata = parseFile(VERBFILE)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, sample(jdata.getElems).pretty)
