module Translate exposing (main)

{- TODO: Make these explicit imports -}

import Api exposing (..)
import Browser
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
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
    { currentConj : QueryResult
    , searchTerm : String
    , errors : String
    }


type QueryResult
    = Resp ResponseObject
    | Empty



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    update GetConjugation initModel


initModel : Model
initModel =
    { searchTerm = ""
    , currentConj = Empty
    , errors = ""
    }



-- UPDATE


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



{- Get Single Conjugation -}


getConjugation : String -> Cmd Msg
getConjugation verb =
    let
        ( endpoint, cmd ) =
            case verb of
                "" ->
                    ( Api.GetAllVerbs, GotAllConjugations )

                default ->
                    ( Api.GetVerbById verb, GotConjugation )
    in
    Api.get endpoint Api.decodeResponseObject cmd



{- Unconjugate -}


getVerbFromConjugation : String -> Cmd Msg
getVerbFromConjugation conjVerb =
    case conjVerb of
        "" ->
            Cmd.none

        default ->
            Api.get (Api.GetVerbByConjugation conjVerb) Api.decodeResponseObject GotVerbFromConjugation



-- UPDATE


type Msg
    = GotAllConjugations Api.GetResponseObjectResult
    | GotConjugation Api.GetResponseObjectResult
    | GetConjugation
    | GetVerbFromConjugation
    | GotVerbFromConjugation Api.GetResponseObjectResult
    | UpdateSearchTerm String
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
            [ class "btn-large orange darken-3 search-btn-show"
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
                (renderMultipleVerbs val)

        Empty ->
            div [] []


renderMultipleVerbs : List (Dict String (List String)) -> List (Html Msg)
renderMultipleVerbs verbList =
    List.map (\v -> renderVerb (pullVerb v)) verbList


pullVerb : Dict String (List String) -> ( String, List String )
pullVerb verbDict =
    case Dict.toList verbDict |> head of
        Nothing ->
            ( "", [ "" ] )

        Just verb ->
            verb


renderVerb : ( String, List String ) -> Html Msg
renderVerb verbTup =
    let
        subjList =
            [ "io"
            , "tu"
            , "lei/lui"
            , "noi"
            , "voi"
            , "loro"
            ]

        verb =
            verbTup |> first

        conjList =
            verbTup |> second
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
