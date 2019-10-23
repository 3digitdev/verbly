module TimeAttack exposing (main)

{- TODO: Make these explicit imports -}

import Api exposing (..)
import Browser
import Browser.Events exposing (onKeyPress)
import Delay exposing (TimeUnit(..), after)
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import List.Extra exposing (elemIndex)
import String exposing (fromInt)
import Task exposing (..)
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
    , guessResult : GuessResult
    , guessIndex : Int
    , correctAnswers : Int
    , wrongAnswers : Int
    }


type QueryResult
    = Resp RandomVerbData
    | Empty


type TimerState
    = Paused
    | Running
    | Finished


type GuessResult
    = Waiting
    | Correct
    | Incorrect



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    update GetNextVerb initModel


initModel : Model
initModel =
    { timeRemaining = 10000
    , state = Paused
    , currentVerb = Empty
    , errors = ""
    , guessResult = Waiting
    , guessIndex = -1
    , correctAnswers = 0
    , wrongAnswers = 0
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        DisableClick _ ->
            ( model, Cmd.none )

        ToggleTimer ->
            ( { model | state = toggleState model }, Cmd.none )

        Reset ->
            init ()

        Countdown _ ->
            let
                ( newTime, state ) =
                    if model.timeRemaining <= 500 then
                        ( 0, Finished )

                    else
                        ( model.timeRemaining - 500, model.state )

                verb =
                    if newTime == 0 then
                        Empty

                    else
                        model.currentVerb
            in
            ( { model | timeRemaining = newTime, state = state, currentVerb = verb }, Cmd.none )

        GetNextVerb ->
            ( model, getVerb )

        GotRandomVerb result ->
            case result of
                Err httpError ->
                    ( { model | currentVerb = Empty, errors = errorToString httpError "" }, Cmd.none )

                Ok verb ->
                    ( { model | currentVerb = Resp verb }, Cmd.none )

        SelectAnswer guessIdx ->
            ( validateGuess model guessIdx, Delay.after 500 Millisecond ResetQuestion )

        ResetQuestion ->
            ( { model | guessResult = Waiting }, getVerb )


getVerb : Cmd Msg
getVerb =
    Api.get Api.GetRandomVerb Api.decodeRandomVerbData GotRandomVerb


toggleState : Model -> TimerState
toggleState model =
    case model.state of
        Paused ->
            Running

        Running ->
            Paused

        default ->
            model.state


validateGuess : Model -> Int -> Model
validateGuess model guessIdx =
    let
        rightIdx =
            case model.currentVerb of
                Empty ->
                    -1

                Resp verbData ->
                    verbData.rightIndex

        result =
            if rightIdx == guessIdx then
                Correct

            else
                Incorrect

        ( correct, wrong ) =
            case result of
                Correct ->
                    ( 1, 0 )

                Incorrect ->
                    ( 0, 1 )

                default ->
                    ( 0, 0 )
    in
    { model
        | guessResult = result
        , state = Running
        , guessIndex = guessIdx
        , correctAnswers = model.correctAnswers + correct
        , wrongAnswers = model.wrongAnswers + wrong
    }



-- UPDATE


type Msg
    = NoOp
    | DisableClick Int
    | ToggleTimer
    | Reset
    | Countdown Time.Posix
    | GetNextVerb
    | GotRandomVerb Api.GetRandomVerbDataResult
    | SelectAnswer Int
    | ResetQuestion



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Running ->
            Time.every 500 Countdown

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
                    "FINISHED!  You got "
                        ++ fromInt model.correctAnswers
                        ++ " out of "
                        ++ fromInt (model.correctAnswers + model.wrongAnswers)
                        ++ " correct!"
    in
    div
        []
        [ node "link"
            [ rel "stylesheet"
            , href "../../../stylesheets/main.css"
            ]
            []
        , renderNavBar model
        , div [ class "sidebar-container" ]
            [ div [] [ h3 [ class "noBtMrgn" ] [ text "Timer" ] ]
            , div
                []
                [ h1 [ class "timer-text" ] [ text (fromInt (ceiling (toFloat model.timeRemaining / 1000))) ] ]
            , div
                []
                [ div []
                    [ h1 [ class "score-text green-text darken-2" ] [ text ("Right: " ++ fromInt model.correctAnswers) ]
                    , h1 [ class "score-text red-text darken-2" ] [ text ("Wrong: " ++ fromInt model.wrongAnswers) ]
                    ]
                ]
            ]
        , div [ class "header-container" ]
            [ div [ class "subject-container center-block" ] [ h1 [ class "center" ] [ text header ] ] ]
        , div
            [ class "container center-block" ]
            [ renderOutput model ]
        ]


timeToSeconds : Int -> String
timeToSeconds ms =
    fromInt (ceiling (toFloat ms / 1000))


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentVerb of
        Resp val ->
            div [ class "content-container" ]
                (renderQuestion model val)

        Empty ->
            div [ class "content-container" ]
                [ button
                    [ class "waves-effect waves-light btn-large xl-button orange darken-3"
                    , onClick Reset
                    ]
                    [ text "Restart" ]
                ]


renderQuestion : Model -> Api.RandomVerbData -> List (Html Msg)
renderQuestion model randomVerbData =
    [ ul
        [ class "collection with-header center-block answers" ]
        (li
            [ class "collection-header center" ]
            [ h3 [] [ text (randomVerbData.subject ++ " ____________") ] ]
            :: List.indexedMap (renderAnswer model) randomVerbData.options
        )
    ]


getResultClass : Model -> Int -> String
getResultClass model idx =
    let
        rightIdx =
            case model.currentVerb of
                Empty ->
                    -1

                Resp verbData ->
                    verbData.rightIndex
    in
    case model.guessResult of
        Waiting ->
            ""

        Correct ->
            if rightIdx == idx then
                " green darken-2"

            else
                ""

        Incorrect ->
            if rightIdx == idx then
                " green"

            else if model.guessIndex == idx then
                " red"

            else
                ""


renderAnswer : Model -> Int -> String -> Html Msg
renderAnswer model index answer =
    let
        msg =
            case model.guessResult of
                Waiting ->
                    SelectAnswer

                default ->
                    DisableClick
    in
    li [ class ("collection-item" ++ getResultClass model index) ]
        [ div
            [ class "answer-container", onClick (msg index) ]
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
