import db_sqlite
import json
import strformat
import strutils

let db = open("../../data/verbly.db", "", "", "")
let jdata = parseFile("../../data/verbs.json")
var last = 0
for verbObj in jdata.getElems:
    for key in verbObj.keys:
        # echo &"INSERT INTO verbs (eng_translation, verb) VALUES ({key}, '')"
        db.exec(sql"INSERT INTO verbs (eng_translation, verb) VALUES (?, ?)", key, "")
        let cur = db.getRow(sql"SELECT * FROM verbs WHERE eng_translation = ?", key)
        if cur[0].parseInt < (last + 1):
            echo &"PROBLEM:  {key}"
        last = cur[0].parseInt
        let conjugations = verbObj[key].getElems
        # echo "INSERT INTO present_indicative (io, tu, lei, lui, noi, voi, loro, vid)"
        # echo &"VALUES ({conjugations[0]}, {conjugations[1]}, {conjugations[2]}, {conjugations[2]}, {conjugations[3]}, {conjugations[4]}, {conjugations[5]}, 0)"
        db.exec(
            sql"INSERT INTO present_indicative (io, tu, lei, lui, noi, voi, loro, vid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            conjugations[0].getStr.replace("\"", ""),
            conjugations[1].getStr.replace("\"", ""),
            conjugations[2].getStr.replace("\"", ""),
            conjugations[2].getStr.replace("\"", ""),
            conjugations[3].getStr.replace("\"", ""),
            conjugations[4].getStr.replace("\"", ""),
            conjugations[5].getStr.replace("\"", ""),
            cur[0].parseInt
        )
db.close()
