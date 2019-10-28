import json
import db_sqlite
import strutils

# database
import verbly_db

proc getVerbData*(db: DbConn, data: tuple[vid: int, verb: string]): JsonNode =
    result = newJObject()
    var conjs = db.getVerbConjugations(data.vid)
    var conjAry = newJArray()
    for conj in conjs:
        conjAry.add(newJString(conj.replace("\"", "")))
    result.add(data.verb, conjAry)
