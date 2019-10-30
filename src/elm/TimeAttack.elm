module TimeAttack exposing (main)

import Api
import Browser
import Components
import Delay exposing (TimeUnit(..), after)
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import List
import String exposing (fromInt)
import Time exposing (every)


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
    = Resp Api.RandomVerbData
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
                    ( { model | currentVerb = Empty, errors = Api.errorToString httpError "" }, Cmd.none )

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

        _ ->
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

                Waiting ->
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

        _ ->
            Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    let
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
    Html.div
        []
        [ Html.node "link"
            [ Attributes.rel "stylesheet"
            , Attributes.href "../../../stylesheets/main.css"
            ]
            []
        , Html.header
            []
            [ Components.renderNavBar "TimeAttack"
            , renderInfoBar model
            ]
        , Html.main_
            []
            [ Html.div
                [ Attributes.class "header-container" ]
                [ Html.div
                    [ Attributes.class "subject-container center-block" ]
                    [ Html.h1
                        [ Attributes.class "center" ]
                        [ Html.text header ]
                    ]
                ]
            , Html.div
                [ Attributes.class "container center-block" ]
                [ renderOutput model ]
            ]
        ]


renderInfoBar : Model -> Html Msg
renderInfoBar model =
    let
        midContent =
            case model.currentVerb of
                Resp val ->
                    []

                Empty ->
                    [ Html.button
                        [ Attributes.class "btn-large orange darken-3 xl-button"
                        , Events.onClick Reset
                        ]
                        [ Html.text "Restart" ]
                    ]
    in
    Html.div
        [ Attributes.class "row indigo lighten-2 white-text" ]
        [ Html.div
            [ Attributes.class "col s5 right-align" ]
            [ Html.h3
                []
                [ Html.text ("Timer: " ++ toTimeFormat (ceiling (toFloat model.timeRemaining / 1000))) ]
            ]
        , Html.div
            [ Attributes.class "col s2 center-align" ]
            midContent
        , Html.div
            [ Attributes.class "col s5 left-align" ]
            [ Html.h3
                []
                [ Html.text
                    ("Score:  "
                        ++ fromInt model.correctAnswers
                        ++ " / "
                        ++ fromInt (model.correctAnswers + model.wrongAnswers)
                    )
                ]
            ]
        ]


toTimeFormat : Int -> String
toTimeFormat time =
    let
        minutes =
            time // 60

        minuteStr =
            if minutes < 10 then
                "0" ++ fromInt minutes

            else
                fromInt minutes

        seconds =
            time |> modBy 60

        secondStr =
            if seconds < 10 then
                "0" ++ fromInt seconds

            else
                fromInt seconds
    in
    minuteStr ++ ":" ++ secondStr


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentVerb of
        Resp val ->
            Html.div
                [ Attributes.class "content-container" ]
                (renderQuestion model val)

        Empty ->
            Html.div
                [ Attributes.class "content-container" ]
                []


renderQuestion : Model -> Api.RandomVerbData -> List (Html Msg)
renderQuestion model randomVerbData =
    [ Html.ul
        [ Attributes.class "collection with-header center-block answers" ]
        (Html.li
            [ Attributes.class "collection-header center" ]
            [ Html.h3 [] [ Html.text (randomVerbData.subject ++ " ____________") ] ]
            :: List.indexedMap (renderAnswer model) randomVerbData.options
        )
    ]


renderAnswer : Model -> Int -> String -> Html Msg
renderAnswer model index answer =
    let
        msg =
            case model.guessResult of
                Waiting ->
                    SelectAnswer

                _ ->
                    DisableClick
    in
    Html.li [ Attributes.class ("collection-item" ++ getResultClass model index) ]
        [ Html.div
            [ Attributes.class "answer-container", Events.onClick (msg index) ]
            [ Html.i [ Attributes.class "medium material-icons answer-num" ] [ Html.text ("looks_" ++ iconIndex (index + 1)) ]
            , Html.div [ Attributes.class "answer center" ]
                [ Html.h4 [] [ Html.text answer ]
                ]
            ]
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


iconIndex : Int -> String
iconIndex idx =
    case idx of
        1 ->
            "one"

        2 ->
            "two"

        _ ->
            fromInt idx
