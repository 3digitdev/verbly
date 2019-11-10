import jester
import json
import strutils
import os

# route imports
import verbs

proc `~`(param: string): string =
    param.replace("%20", " ")

router verbly:
    get "/verbs":
        let ret = getAllVerbs()
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)

    get "/verbs/@verb":
        let ret = getVerbByName(~(@"verb"))
        if ret.len > 0:
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verbs/conjugation/@conj":
        let ret = getVerbByConjugation(~(@"conj"))
        if ret.len > 0:
            resp(Http200, {"Access-Control-Allow-Origin":"*"}, ret.pretty)
        resp(Http404, {"Access-Control-Allow-Origin":"*"}, (%*{}).pretty)

    get "/verb/random":
        var outData = getRandomVerb()
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, outData.pretty)

when isMainModule:
    echo getEnv("PORT")
    let port = getEnv("PORT").parseInt().Port
    settings = newSettings(port = port)
    var server = initJester(verbly, settings=settings)
    server.serve()
