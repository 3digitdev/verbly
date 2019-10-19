module Practice exposing (main)

{- TODO: Make these explicit imports -}

import Browser
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, dict, list, string)
import List exposing (..)
import Random exposing (..)
import Tuple exposing (..)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { currentVerb : QueryResult
    , seed : Random.Seed
    , playerGuess : Maybe ResponseObject
    }


type alias ResponseObject =
    Dict String (List String)


type QueryResult
    = Resp ResponseObject
    | Empty



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    update NoOp initModel


initModel : Model
initModel =
    { currentVerb = Empty
    , seed = Random.initialSeed 0
    , playerGuess = Nothing
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GenerateCard ->
            ( model, getRandomVerb )

        GetRandomVerb result ->
            case result of
                Err httpError ->
                    ( model, Cmd.none )

                Ok verb ->
                    ( { model | currentVerb = Resp verb, playerGuess = randomizeVerb verb }, Cmd.none )

        UpdatePlayerGuess guess ->
            case model.playerGuess of
                Nothing ->
                    ( model, Cmd.none )

                Just guess ->
                    ( { model | playerGuess = Resp guess }, Cmd.none )



{- Helper Functions for API Interface -}
-- TODO: Build an "api endpoint builder" to replace the `api` function


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


decodeObject : JD.Decoder ResponseObject
decodeObject =
    JD.dict (JD.list JD.string)


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



{- Get Single Conjugation -}


getRandomVerb : Cmd Msg
getRandomVerb =
    Http.get
        { url = api "/verb/random" ""
        , expect = Http.expectJson GotConjugation decodeObject
        }



-- UPDATE


type Msg
    = GenerateCard
    | GetRandomVerb (Result Http.Error ResponseObject)
    | UpdatePlayerGuess (Maybe ResponseObject)
    | NoOp



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


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



{- Nav Bar -}


renderNavBar : Model -> Html Msg
renderNavBar model =
    nav []
        [ div
            [ class "nav-wrapper indigo" ]
            [ a [ href "#", class "brand-logo center" ]
                [ text "Verbly" ]
            , ul
                [ class "left" ]
                [ li [] [ a [ href "#" ] [ text "Practice" ] ]
                , li [] [ a [ href "#" ] [ text "Translate" ] ]
                ]
            ]
        ]



{- Search Bar -}


renderInput : Model -> Html Msg
renderInput model =
    div [ class "search-container" ]
        [ input
            [ placeholder "Enter Search Term"
            , Html.Attributes.id "search"
            , Html.Attributes.value model.playerGuess
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



{- Content -}


renderErrors : Model -> Html Msg
renderErrors model =
    case model.errors of
        "" ->
            text model.errors

        default ->
            div [ class "content-container" ] [ h2 [] [ text model.errors ] ]


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentConj of
        Resp val ->
            div [ class "content-container" ]
                (List.map (\v -> renderVerb (first v) (second v)) (Dict.toList val))

        Empty ->
            div [] []


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


renderConjRow : String -> String -> Html Msg
renderConjRow subj conj =
    tr [] [ td [] [ text subj ], td [] [ text conj ] ]
