module Main exposing (main)

import Browser
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, dict, list, string)
import List exposing (..)
import Tuple exposing (..)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


decodeVerb : JD.Decoder (List String)
decodeVerb =
    JD.list JD.string


decodeAll : JD.Decoder (Dict String (List String))
decodeAll =
    JD.dict (JD.list JD.string)


type alias Model =
    { currentConj : QueryResult
    , searchVerb : String
    , errors : String
    }


type QueryResult
    = Single (List String)
    | All (Dict String (List String))
    | Empty


initModel : Model
initModel =
    { searchVerb = ""
    , currentConj = Empty
    , errors = ""
    }


init : () -> ( Model, Cmd Msg )
init _ =
    update GetConjugation initModel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateSearchTerm content ->
            ( { model | searchVerb = content }, Cmd.none )

        GetConjugation ->
            ( model, getConjugation model.searchVerb )

        GotAllConjugations result ->
            case result of
                Err httpError ->
                    ( { model | errors = errorToString httpError model.searchVerb, currentConj = Empty }, Cmd.none )

                Ok conj ->
                    ( { model | currentConj = All conj, errors = "" }, Cmd.none )

        GotConjugation result ->
            case result of
                Err httpError ->
                    ( { model | errors = errorToString httpError model.searchVerb, currentConj = Empty }, Cmd.none )

                Ok conj ->
                    ( { model | currentConj = Single conj, errors = "" }, Cmd.none )


api : String -> String
api verb =
    let
        base =
            "http://0.0.0.0:5000/verbs"
    in
    case verb of
        "" ->
            base

        default ->
            base ++ "/" ++ verb


getConjugation : String -> Cmd Msg
getConjugation verb =
    let
        expect =
            case verb of
                "" ->
                    Http.expectJson GotAllConjugations decodeAll

                default ->
                    Http.expectJson GotConjugation decodeVerb
    in
    Http.get
        { url = api verb
        , expect = expect
        }


errorToString : Http.Error -> String -> String
errorToString err verb =
    case err of
        Http.Timeout ->
            "Timeout exceeded"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus resp ->
            String.fromInt resp ++ ": Invalid verb '" ++ verb ++ "'"

        Http.BadBody text ->
            "Unexpected response from api: " ++ text

        Http.BadUrl url ->
            "Malformed url: " ++ url



-- UPDATE


type Msg
    = GotAllConjugations (Result Http.Error (Dict String (List String)))
    | GotConjugation (Result Http.Error (List String))
    | GetConjugation
    | UpdateSearchTerm String
    | NoOp



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


renderVerb : String -> List String -> Html Msg
renderVerb verb conj =
    div
        []
        [ strong [] [ text (verb ++ ": ") ]
        , p [] [ text (String.join ", " conj) ]
        ]


renderAll : List ( String, List String ) -> List (Html Msg)
renderAll allVerbs =
    List.map (\v -> renderVerb (first v) (second v)) allVerbs


renderConjOutput : Model -> Html Msg
renderConjOutput model =
    case model.currentConj of
        All valDict ->
            div
                []
                (renderAll (Dict.toList valDict))

        Single val ->
            renderVerb model.searchVerb val

        Empty ->
            div [] []


view : Model -> Html Msg
view model =
    div
        []
        [ input
            [ onInput UpdateSearchTerm, Html.Attributes.value model.searchVerb ]
            []
        , button
            [ onClick GetConjugation ]
            [ text "Conjugate" ]
        , div [] [ text model.errors ]
        , renderConjOutput model
        ]
