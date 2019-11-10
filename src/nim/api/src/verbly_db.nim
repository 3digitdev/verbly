import db_sqlite
import strutils
import strformat
import sequtils

const db_name = "../../../data/verbly.db"
# Local Dev
# const db_name = "../../../../data/verbly.db"

# SQL COMMAND TEMPLATES
const getAllEngVerbs = sql"SELECT vid, eng_translation FROM verbs"
const getEngVerbExact = sql"SELECT vid, eng_translation FROM verbs WHERE eng_translation = ?"
const getEngVerbPartial = sql"SELECT vid, eng_translation FROM verbs WHERE eng_translation LIKE ?"
const getEngVerbByVid = sql"SELECT vid, eng_translation FROM verbs WHERE vid = ?"
const getVerbConj = sql"SELECT io, tu, lei, noi, voi, loro FROM present_indicative WHERE vid = ?"
const findConjVerb = sql"SELECT vid FROM present_indicative WHERE io = ? or tu = ? or lei = ? or lui = ? or noi = ? or voi = ? or loro = ?"
const getRandVerb = sql"SELECT vid, eng_translation FROM verbs ORDER BY random() LIMIT 1"

type VerbData = tuple
    vid: int
    verb: string

proc contains[VerbData](a: seq[VerbData], b: string): bool =
    return find(a.mapIt(it.verb), b) >= 0

template withSqliteDb*(dbc, actions: untyped): untyped =
    var dbc: DbConn
    try:
        dbc = open(db_name, "", "", "")
        try:
            actions
        finally:
            dbc.close()
    except:
        stderr.writeLine(getCurrentExceptionMsg())

proc getAllVerbs*(db: DbConn): seq[VerbData] =
    for match in db.getAllRows(getAllEngVerbs):
        result.add((match[0].parseInt, match[1]))

proc matchEnglishVerb*(db: DbConn, verb: string): seq[VerbData] =
    # Prioritize exact matches -- let's get those first
    for exact in db.getAllRows(getEngVerbExact, &"{verb}"):
        result.add((exact[0].parseInt, exact[1]))
    # Now get the partial matches
    for partial in db.getAllRows(getEngVerbPartial, &"%{verb}%"):
        if partial[1] in result:
            echo &"already found {partial[1]}"
        if not (partial[1] in result):
            result.add((partial[0].parseInt, partial[1]))

proc getVerbConjugations*(db: DbConn, vid: int): seq[string] =
    db.getRow(getVerbConj, $vid)

proc getVerbByConjugation*(db: DbConn, conjugation: string): VerbData =
    var match = db.getRow(findConjVerb, sequtils.repeat(conjugation, 7))
    if match.len > 0:
        var ret = db.getRow(getEngVerbByVid, match[0])
        result = (ret[0].parseInt, ret[1])
    else:
        result = (-1, "")

proc getRandomVerb*(db: DbConn): VerbData =
    var rndVerb = db.getRow(getRandVerb)
    result = (rndVerb[0].parseInt, rndVerb[1])
