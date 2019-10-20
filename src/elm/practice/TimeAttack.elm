module TimeAttack exposing (main)

{- TODO: Make these explicit imports -}

import Api exposing (..)
import Browser
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import String exposing (fromInt)
import Time exposing (Posix, every)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { timeRemaining : Int
    , state : TimerState
    , currentVerb : QueryResult
    , errors : String
    }


type QueryResult
    = Resp RandomVerbData
    | Empty


type TimerState
    = Paused
    | Running
    | Finished



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    update GetNextVerb initModel


initModel : Model
initModel =
    { timeRemaining = 30
    , state = Paused
    , currentVerb = Empty
    , errors = ""
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ToggleTimer ->
            ( { model | state = toggleState model }, Cmd.none )

        ResetTimer ->
            ( initModel, Cmd.none )

        Countdown _ ->
            let
                ( newTime, state ) =
                    case model.timeRemaining of
                        1 ->
                            ( 0, Finished )

                        default ->
                            ( model.timeRemaining - 1, model.state )
            in
            ( { model | timeRemaining = newTime, state = state }, Cmd.none )

        GetNextVerb ->
            ( model, Api.get Api.GetRandomVerb Api.decodeRandomVerbData GotRandomVerb )

        GotRandomVerb result ->
            case result of
                Err httpError ->
                    ( { model | currentVerb = Empty, errors = errorToString httpError "" }, Cmd.none )

                Ok verb ->
                    ( { model | currentVerb = Resp verb }, Cmd.none )


toggleState : Model -> TimerState
toggleState model =
    case model.state of
        Paused ->
            Running

        Running ->
            Paused

        default ->
            model.state



-- UPDATE


type Msg
    = NoOp
    | ToggleTimer
    | ResetTimer
    | Countdown Time.Posix
    | GetNextVerb
    | GotRandomVerb Api.GetRandomVerbDataResult



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Running ->
            Time.every 1000 Countdown

        default ->
            Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    let
        ( btnState, btnClass ) =
            case model.state of
                Paused ->
                    ( "Start", "-show" )

                Running ->
                    ( "Stop", "-show" )

                Finished ->
                    ( "Restart", "" )

        header =
            case model.currentVerb of
                Resp val ->
                    val.englishSubject ++ "  " ++ val.verb

                Empty ->
                    ""
    in
    div
        []
        [ node "link"
            [ rel "stylesheet"
            , href "../../../stylesheets/main.css"
            ]
            []
        , renderNavBar model
        , div [ class "timer-container" ] [ h1 [ class "timer-text" ] [ text (fromInt model.timeRemaining) ] ]
        , div [ class "header-container" ]
            [ div [ class "subject-container center-block" ] [ h1 [ class "center" ] [ text header ] ] ]
        , div
            [ class "container center-block" ]
            [ renderOutput model ]
        ]


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentVerb of
        Resp val ->
            div [ class "content-container" ]
                (renderQuestion val)

        Empty ->
            div [] []


renderQuestion : Api.RandomVerbData -> List (Html Msg)
renderQuestion randomVerbData =
    [ ul
        [ class "collection with-header center-block answers" ]
        (li
            [ class "collection-header center" ]
            [ h3 [] [ text (randomVerbData.subject ++ " ____________") ] ]
            :: List.indexedMap renderAnswer randomVerbData.options
        )
    ]


renderAnswer : Int -> String -> Html Msg
renderAnswer index answer =
    li [ class "collection-item" ]
        [ div
            [ class "answer-container" ]
            [ i [ class "medium material-icons answer-num" ] [ text ("looks_" ++ iconIndex (index + 1)) ]
            , div [ class "answer center" ]
                [ h4 [] [ text answer ]
                ]
            ]
        ]


iconIndex : Int -> String
iconIndex idx =
    case idx of
        1 ->
            "one"

        2 ->
            "two"

        default ->
            fromInt idx



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
