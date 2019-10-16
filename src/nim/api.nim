import jester
import json
import strformat

const VERBFILE = "../../data/verbs.json"

routes:
    get "/verbs":
        let jdata = parseFile(VERBFILE)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, jdata.pretty)

    get "/verbs/@verb":
        let jdata = parseFile(VERBFILE)
        if jdata.hasKey(@"verb"):
            var ret = newJObject()
            ret.add(@"verb", jdata[@"verb"])
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)
        else:
            resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/base/@conj":
        let jdata = parseFile(VERBFILE)
        for k, v in jdata.pairs():
            if v.contains(newJString(@"conj")):
                resp(Http200, {"Access-Control-Allow-Origin":"*"}, (%*{ k: v }).pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)
