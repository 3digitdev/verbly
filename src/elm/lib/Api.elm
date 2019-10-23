module Api exposing (ResponseObject, get, Endpoint(..), RandomVerbData, errorToString, decodeRandomVerbData, GetRandomVerbDataResult, decodeResponseObject)

import Dict exposing (Dict)
import Http
import Json.Decode as JD exposing (dict, list, string)


type alias ResponseObject =
    List (Dict String (List String))


type alias RandomVerbData =
    { verb : String
    , subject : String
    , englishSubject : String
    , right : String
    , rightIndex : Int
    , options : List String
    }


type alias GetRandomVerbDataResult =
    Result Http.Error RandomVerbData


type Endpoint
    = GetAllVerbs
    | GetVerbById String
    | GetVerbByConjugation String
    | GetRandomVerb



{- Helper Functions for API Interface -}
-- TODO: Build an "api endpoint builder" to replace the `api` function


urlBase : String
urlBase =
    "http://localhost:5000"


urlBuilder : Endpoint -> String
urlBuilder endpoint =
    case endpoint of
        GetAllVerbs ->
            urlBase ++ "/verbs"

        GetVerbById vid ->
            urlBase ++ "/verbs/" ++ vid

        GetVerbByConjugation cid ->
            urlBase ++ "/verbs/conjugation/" ++ cid

        GetRandomVerb ->
            urlBase ++ "/verb/random"


decodeResponseObject : JD.Decoder ResponseObject
decodeResponseObject =
    JD.list (JD.dict (JD.list JD.string))


decodeRandomVerbData : JD.Decoder RandomVerbData
decodeRandomVerbData =
    JD.map6 RandomVerbData
        (JD.field "verb" JD.string)
        (JD.field "subject" JD.string)
        (JD.field "englishSubject" JD.string)
        (JD.field "right" JD.string)
        (JD.field "rightIndex" JD.int)
        (JD.field "options" (JD.list JD.string))


get : Endpoint -> JD.Decoder a -> (Result Http.Error a -> msg) -> Cmd msg
get endpoint decoder cmd =
    Http.get
        { url = urlBuilder endpoint
        , expect = Http.expectJson cmd decoder
        }


--getWithDecoder : Endpoint -> JD.Decoder a -> (Result Http.Error a -> msg) -> Cmd msg
--getWithDecoder endpoint decoder cmd =
--    Http.get
--        { url = urlBuilder endpoint
--        , expect = Http.expectJson cmd decoder
--        }


errorToString : Http.Error -> String -> String
errorToString err verb =
    case err of
        Http.Timeout ->
            "Timeout exceeded"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus _ ->
            "No verb matches '" ++ verb ++ "'"

        Http.BadBody text ->
            "Unexpected response from api: " ++ text

        Http.BadUrl url ->
            "Malformed url: " ++ url
