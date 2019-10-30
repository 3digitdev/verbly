module Translate exposing (main)

import Api
import Browser
import Components
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import List


main : Program () Model Msg
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
    = Resp Api.ResponseObject
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
        UpdateSearchTerm content ->
            ( { model | searchTerm = content }, Cmd.none )

        GetConjugation ->
            ( model, getConjugation model.searchTerm )

        GotConjugation result ->
            case result of
                Err httpError ->
                    ( { model | errors = Api.errorToString httpError model.searchTerm, currentConj = Empty }, Cmd.none )

                Ok conj ->
                    ( { model | currentConj = Resp conj, errors = "" }, Cmd.none )

        GetVerbFromConjugation ->
            ( model, getVerbFromConjugation model.searchTerm )



{- Get Single Conjugation -}


getConjugation : String -> Cmd Msg
getConjugation verb =
    let
        endpoint =
            if verb == "" then
                Api.GetAllVerbs

            else
                Api.GetVerbById verb
    in
    Api.get endpoint Api.decodeResponseObject GotConjugation



{- Unconjugate -}


getVerbFromConjugation : String -> Cmd Msg
getVerbFromConjugation conjVerb =
    if conjVerb == "" then
        Cmd.none

    else
        Api.get (Api.GetVerbByConjugation conjVerb) Api.decodeResponseObject GotConjugation



-- UPDATE


type Msg
    = GotConjugation Api.GetResponseObjectResult
    | GetConjugation
    | GetVerbFromConjugation
    | UpdateSearchTerm String



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Html.div
        []
        [ Html.node "link"
            [ Attributes.rel "stylesheet"
            , Attributes.href "../../public/stylesheets/main.css"
            ]
            []
        , Components.renderNavBar "Translate"
        , renderSearchBar model
        , Html.div
            [ Attributes.class "container center-block" ]
            [ Html.div
                [ Attributes.class "center-block" ]
                [ renderErrors model
                , renderOutput model
                ]
            ]
        ]



{- Search Bar -}


renderSearchBar : Model -> Html Msg
renderSearchBar model =
    Html.div [ Attributes.class "search-container" ]
        [ Html.input
            [ Attributes.placeholder "Enter Search Term"
            , Attributes.id "search"
            , Attributes.value model.searchTerm
            , Events.onInput UpdateSearchTerm
            , Attributes.class "search-bar"
            ]
            []
        , Html.button
            [ Attributes.class "btn-large orange darken-3 search-btn-show"
            , Events.onClick GetConjugation
            ]
            [ Html.text "Conjugate" ]
        , Html.button
            [ Attributes.class "btn-large lime darken-2 search-btn-show"
            , Events.onClick GetVerbFromConjugation
            ]
            [ Html.text "Unconjugate" ]
        ]



{- Content -}


renderErrors : Model -> Html Msg
renderErrors model =
    if model.errors == "" then
        Html.text model.errors

    else
        Html.div [ Attributes.class "content-container" ] [ Html.h2 [] [ Html.text model.errors ] ]


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentConj of
        Resp val ->
            Html.div [ Attributes.class "content-container" ]
                (renderMultipleVerbs val)

        Empty ->
            Html.text ""


renderMultipleVerbs : List (Dict String (List String)) -> List (Html Msg)
renderMultipleVerbs verbList =
    List.map (pullVerb >> renderVerb) verbList


pullVerb : Dict String (List String) -> ( String, List String )
pullVerb verbDict =
    case Dict.toList verbDict |> List.head of
        Nothing ->
            ( "", [] )

        Just verb ->
            verb


renderVerb : ( String, List String ) -> Html Msg
renderVerb ( verb, conjList ) =
    Html.table
        [ Attributes.class "striped centered conj-table" ]
        [ Html.thead
            []
            [ Html.tr []
                [ Html.th [ Attributes.colspan 2, Attributes.class "center-align" ] [ Html.h5 [] [ Html.text (String.toUpper verb) ] ] ]
            , Html.tr []
                [ Html.th [] [ Html.text "Subject" ]
                , Html.th [] [ Html.text "Conjugation" ]
                ]
            ]
        , Html.tbody
            []
            (List.map2 renderConjRow subjList conjList)
        ]


subjList : List String
subjList =
    [ "io"
    , "tu"
    , "lei/lui"
    , "noi"
    , "voi"
    , "loro"
    ]


renderConjRow : String -> String -> Html Msg
renderConjRow subj conj =
    Html.tr [] [ Html.td [] [ Html.text subj ], Html.td [] [ Html.text conj ] ]
