module Main exposing (main)

{- TODO: Make these explicit imports -}

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
            "No verb matches '" ++ verb ++ "'"

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
            [ "io"
            , "tu"
            , "lei/lui"
            , "noi"
            , "voi"
            , "loro"
            ]
    in
    table
        [ class "striped centered conj-table" ]
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


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentConj of
        Resp val ->
            div [ class "content-container" ]
                (List.map (\v -> renderVerb (first v) (second v)) (Dict.toList val))

        Empty ->
            div [] []


renderErrors : Model -> Html Msg
renderErrors model =
    case model.errors of
        "" ->
            text model.errors

        default ->
            div [ class "content-container" ] [ h2 [] [ text model.errors ] ]


renderNavBar : Model -> Html Msg
renderNavBar model =
    nav []
        [ div
            [ class "nav-wrapper indigo" ]
            [ a [ href "#", class "brand-logo center" ]
                [ text "Verbly" ]
            , ul
                [ class "left" ]
                [ li [] [ a [ href "#" ] [ text "Conjugate" ] ]
                , li [] [ a [ href "#" ] [ text "Translate" ] ]
                ]
            ]
        ]


renderSearchBar : Model -> Html Msg
renderSearchBar model =
    div [ class "search-container" ]
        [ input
            [ placeholder "Enter Search Term"
            , Html.Attributes.id "search"
            , Html.Attributes.value model.searchTerm
            , onInput UpdateSearchTerm
            , class "search-bar"
            ]
            []
        , button
            [ class "btn-large orange darken-3 search-btn"
            , onClick GetConjugation
            ]
            [ text "Conjugate" ]
        , button
            [ class "btn-large lime darken-2 search-btn"
            , onClick GetVerbFromConjugation
            ]
            [ text "Unconjugate" ]
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
        , renderSearchBar model
        , div
            [ class "container center-block" ]
            [ div
                [ class "center-block" ]
                [ renderErrors model
                , renderOutput model
                ]
            ]
        ]
