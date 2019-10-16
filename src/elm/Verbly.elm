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


decodeObject : JD.Decoder ResponseObject
decodeObject =
    JD.dict (JD.list JD.string)


type alias Model =
    { currentConj : QueryResult
    , searchTerm : String
    , errors : String
    }


type alias ResponseObject =
    Dict String (List String)


type QueryResult
    = Resp ResponseObject
    | Empty


initModel : Model
initModel =
    { searchTerm = ""
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
            ( { model | searchTerm = content }, Cmd.none )

        GetConjugation ->
            ( model, getConjugation model.searchTerm )

        GotAllConjugations result ->
            case result of
                Err httpError ->
                    ( { model | errors = errorToString httpError model.searchTerm, currentConj = Empty }, Cmd.none )

                Ok conj ->
                    ( { model | currentConj = Resp conj, errors = "" }, Cmd.none )

        GotConjugation result ->
            case result of
                Err httpError ->
                    ( { model | errors = errorToString httpError model.searchTerm, currentConj = Empty }, Cmd.none )

                Ok conj ->
                    ( { model | currentConj = Resp conj, errors = "" }, Cmd.none )

        GetVerbFromConjugation ->
            ( model, getVerbFromConjugation model.searchTerm )

        GotVerbFromConjugation result ->
            case result of
                Err httpError ->
                    ( { model | errors = errorToString httpError model.searchTerm, currentConj = Empty }, Cmd.none )

                Ok conj ->
                    ( { model | currentConj = Resp conj, errors = "" }, Cmd.none )


api : String -> String -> String
api route data =
    let
        base =
            "http://0.0.0.0:5000" ++ route
    in
    case data of
        "" ->
            base

        default ->
            base ++ "/" ++ data


getConjugation : String -> Cmd Msg
getConjugation verb =
    let
        expect =
            case verb of
                "" ->
                    Http.expectJson GotAllConjugations decodeObject

                default ->
                    Http.expectJson GotConjugation decodeObject
    in
    Http.get
        { url = api "/verbs" verb
        , expect = expect
        }


getVerbFromConjugation : String -> Cmd Msg
getVerbFromConjugation conjVerb =
    case conjVerb of
        "" ->
            Cmd.none

        default ->
            Http.get
                { url = api "/base" conjVerb
                , expect = Http.expectJson GotVerbFromConjugation decodeObject
                }


errorToString : Http.Error -> String -> String
errorToString err verb =
    case err of
        Http.Timeout ->
            "Timeout exceeded"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus resp ->
            String.fromInt resp ++ ": '" ++ verb ++ "' Not Found"

        Http.BadBody text ->
            "Unexpected response from api: " ++ text

        Http.BadUrl url ->
            "Malformed url: " ++ url



-- UPDATE


type Msg
    = GotAllConjugations (Result Http.Error ResponseObject)
    | GotConjugation (Result Http.Error ResponseObject)
    | GetConjugation
    | GetVerbFromConjugation
    | GotVerbFromConjugation (Result Http.Error ResponseObject)
    | UpdateSearchTerm String
    | NoOp



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


renderConjRow : String -> String -> Html Msg
renderConjRow subj conj =
    tr [] [ td [] [ text subj ], td [] [ text conj ] ]


renderVerb : String -> List String -> Html Msg
renderVerb verb conjList =
    let
        subjList =
            [ "IO"
            , "TU"
            , "LEI/LUI"
            , "NOI"
            , "VOI"
            , "LORO"
            ]
    in
    li [ class "collection-item" ]
        [ table
            [ class "striped centered" ]
            [ thead
                []
                [ tr []
                    [ th [ colspan 2, class "center-align" ] [ h5 [] [ text (String.toUpper verb) ] ] ]
                , tr []
                    [ th [] [ text "Subject" ]
                    , th [] [ text "Conjugation" ]
                    ]
                ]
            , tbody
                []
                (List.map2 renderConjRow subjList conjList)
            ]
        ]


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentConj of
        Resp val ->
            div []
                [ ul
                    [ class "collection" ]
                    (List.map (\v -> renderVerb (first v) (second v)) (Dict.toList val))
                ]

        Empty ->
            div [] []


renderNavBar : Model -> Html Msg
renderNavBar model =
    nav []
        [ div
            [ class "nav-wrapper indigo" ]
            [ a [ href "#", class "brand-logo center" ]
                [ text "Verbly" ]
            , ul
                [ id "nav-mobile", class "left hide-on-med-and-down" ]
                [ li [] [ a [ href "#" ] [ text "Conjugate" ] ]
                , li [] [ a [ href "#" ] [ text "Translate" ] ]
                ]
            ]
        ]


renderSearchBar : Model -> Html Msg
renderSearchBar model =
    div
        [ class "col s12" ]
        [ div
            [ class "row" ]
            [ div
                [ class "input-field col s4" ]
                [ input
                    [ placeholder "Enter Search Term"
                    , Html.Attributes.id "search"
                    , Html.Attributes.value model.searchTerm
                    , onInput UpdateSearchTerm
                    ]
                    [ label
                        [ for "search" ]
                        [ text "Search:" ]
                    ]
                ]
            ]
        , div
            [ class "row" ]
            [ button
                [ class "waves-effect waves-light btn-large orange darken-3 col s2"
                , onClick GetConjugation
                ]
                [ text "Conjugate" ]
            , button
                [ class "waves-effect waves-light btn-large lime darken-2 col s2"
                , onClick GetVerbFromConjugation
                ]
                [ text "Unconjugate" ]
            ]
        ]


view : Model -> Html Msg
view model =
    div
        []
        [ node "link"
            [ rel "stylesheet"
            , href "../../stylesheets/main.css"
            ]
            []
        , renderNavBar model
        , div
            [ class "container center-block" ]
            [ div
                [ class "center-block" ]
                [ renderSearchBar model
                , div [] [ text model.errors ]
                , renderOutput model
                ]
            ]
        ]
