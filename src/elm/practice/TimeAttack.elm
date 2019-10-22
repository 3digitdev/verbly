module TimeAttack exposing (main)

{- TODO: Make these explicit imports -}

import Api exposing (..)
import Browser
import Browser.Events exposing (onKeyPress)
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import List.Extra exposing (elemIndex)
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
    , guessResult : GuessResult
    , guessIndex : Int
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
    { timeRemaining = 30
    , state = Paused
    , currentVerb = Empty
    , errors = ""
    , guessResult = Waiting
    , guessIndex = -1
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

        SelectAnswer guessIdx ->
            ( validateGuess model guessIdx, Cmd.none )


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
    in
    { model
        | guessResult =
            if rightIdx == guessIdx then
                Correct

            else
                Incorrect
        , guessIndex = guessIdx
    }



-- UPDATE


type Msg
    = NoOp
    | ToggleTimer
    | ResetTimer
    | Countdown Time.Posix
    | GetNextVerb
    | GotRandomVerb Api.GetRandomVerbDataResult
    | SelectAnswer Int



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
        , div
            [ class "timer-container" ]
            [ h1 [ class "timer-text" ] [ text (fromInt model.timeRemaining) ] ]
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
                (renderQuestion model val)

        Empty ->
            div [] []


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
                " red darken-2"

            else
                ""


renderAnswer : Model -> Int -> String -> Html Msg
renderAnswer model index answer =
    li [ class ("collection-item" ++ getResultClass model index) ]
        [ div
            [ class "answer-container", onClick (SelectAnswer index) ]
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
