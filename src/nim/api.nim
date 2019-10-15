import jester
import json

const VERBFILE = "../../data/verbs.json"

routes:
    get "/verbs":
        let jdata = parseFile(VERBFILE)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, jdata.pretty)

    get "/verbs/@verb":
        let jdata = parseFile(VERBFILE)
        if jdata.hasKey(@"verb"):
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, jdata[@"verb"].pretty)
        else:
            resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)
