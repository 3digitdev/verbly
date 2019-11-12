port module TimeAttack exposing (main)

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



-- PORTS


port keyPressed : (Int -> msg) -> Sub msg



-- MODEL


type alias Model =
    { timeRemaining : Int
    , timerSeconds : Int
    , timerMinutes : Int
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
    = Loading
    | Running
    | Finished
    | Editing


type GuessResult
    = Waiting
    | Correct
    | Incorrect


type TimerInput
    = Minute
    | Second



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    update GetNextVerb (initModel ( 0, 10 ))


initModel : ( Int, Int ) -> Model
initModel ( min, sec ) =
    { timeRemaining = (min * 60 * 1000) + (sec * 1000)
    , timerSeconds = sec
    , timerMinutes = min
    , state = Loading
    , currentVerb = Empty
    , errors = ""
    , guessResult = Waiting
    , guessIndex = -1
    , correctAnswers = 0
    , wrongAnswers = 0
    }



-- UPDATE


type Msg
    = NoOp
    | DisableClick Int
    | Reset
    | Countdown Time.Posix
    | GetNextVerb
    | GotRandomVerb Api.GetRandomVerbDataResult
    | SelectAnswer Int
    | ResetQuestion
    | ToggleTimerEdit
    | ChangeTime TimerInput String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        DisableClick _ ->
            ( model, Cmd.none )

        Reset ->
            let
                newModel =
                    initModel ( model.timerMinutes, model.timerSeconds )
            in
            ( newModel, getVerb newModel )

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
            ( model, getVerb model )

        GotRandomVerb result ->
            case result of
                Err httpError ->
                    ( { model | currentVerb = Empty, errors = Api.errorToString httpError "" }, Cmd.none )

                Ok verb ->
                    ( { model | currentVerb = Resp verb }, Cmd.none )

        SelectAnswer guessIdx ->
            ( validateGuess model guessIdx, Delay.after 500 Millisecond ResetQuestion )

        ResetQuestion ->
            ( { model | guessResult = Waiting }, getVerb model )

        ToggleTimerEdit ->
            ( { model | state = toggleTimerState model }, Cmd.none )

        ChangeTime timerType newTime ->
            let
                time =
                    case String.toInt newTime of
                        Nothing ->
                            0

                        Just t ->
                            t
            in
            ( modifyTimer model timerType time, Cmd.none )


modifyTimer : Model -> TimerInput -> Int -> Model
modifyTimer model timerType newTime =
    let
        newModel =
            case timerType of
                Minute ->
                    { model | timerMinutes = newTime }

                Second ->
                    { model | timerSeconds = newTime }
    in
    { newModel | timeRemaining = (newModel.timerMinutes * 60 * 1000) + (newModel.timerSeconds * 1000) }


getVerb : Model -> Cmd Msg
getVerb model =
    case model.state of
        Finished ->
            Cmd.none

        default ->
            Api.get Api.GetRandomVerb Api.decodeRandomVerbData GotRandomVerb


toggleTimerState : Model -> TimerState
toggleTimerState model =
    case model.state of
        Loading ->
            Editing

        Editing ->
            Loading

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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Running ->
            case model.guessResult of
                Waiting ->
                    Sub.batch [ keyPressed SelectAnswer, Time.every 500 Countdown ]

                default ->
                    Time.every 500 Countdown

        Loading ->
            keyPressed SelectAnswer

        default ->
            Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    let
        header =
            case model.state of
                Finished ->
                    Html.div []
                        [ Html.h1 [ Attributes.class "center" ] [ Html.text "FINISHED!" ]
                        , Html.h2 []
                            [ Html.text
                                ("You got "
                                    ++ fromInt model.correctAnswers
                                    ++ " out of "
                                    ++ fromInt (model.correctAnswers + model.wrongAnswers)
                                    ++ " correct!"
                                )
                            ]
                        ]

                default ->
                    case model.currentVerb of
                        Resp val ->
                            Html.h1 [ Attributes.class "center" ] [ Html.text (val.englishSubject ++ "  " ++ val.verb) ]

                        Empty ->
                            Html.div
                                []
                                [ Html.h1 [ Attributes.class "center" ] [ Html.text "Loading..." ]
                                , Html.div
                                    [ Attributes.class "progress" ]
                                    [ Html.div [ Attributes.class "indeterminate" ] [] ]
                                ]
    in
    Html.div
        []
        [ Html.header
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
                    [ header ]
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
            case model.state of
                Finished ->
                    [ Html.button
                        [ Attributes.class "btn-large orange darken-3 xl-button"
                        , Events.onClick Reset
                        ]
                        [ Html.text "Restart" ]
                    ]

                default ->
                    []

        ( cmd, icon ) =
            case model.state of
                Editing ->
                    ( ToggleTimerEdit, "check" )

                Loading ->
                    ( ToggleTimerEdit, "mode_edit" )

                default ->
                    ( NoOp, "block" )
    in
    Html.div
        [ Attributes.class "row indigo lighten-2 white-text" ]
        [ Html.div
            [ Attributes.class "col s3 m4 l5 right-align" ]
            [ Html.h3
                []
                (List.append
                    (renderTimer model)
                    [ Html.i
                        [ Attributes.class "small material-icons edit-time"
                        , Events.onClick cmd
                        ]
                        [ Html.text icon ]
                    ]
                )
            ]
        , Html.div
            [ Attributes.class "col s6 m4 l2 center-align" ]
            midContent
        , Html.div
            [ Attributes.class "col s3 m4 l5 left-align" ]
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


renderTimer : Model -> List (Html Msg)
renderTimer model =
    case model.state of
        Editing ->
            [ Html.text "Timer: "
            , Html.input
                [ Attributes.class "minute indigo lighten-2 white-text right-align"
                , Attributes.value (String.fromInt model.timerMinutes)
                , Attributes.type_ "number"
                , Attributes.min "0"
                , Attributes.max "10"
                , Events.onInput (ChangeTime Minute)
                ]
                []
            , Html.text ":"
            , Html.input
                [ Attributes.class "second indigo lighten-2 white-text"
                , Attributes.value (String.fromInt model.timerSeconds)
                , Attributes.type_ "number"
                , Attributes.min "0"
                , Attributes.max "59"
                , Events.onInput (ChangeTime Second)
                ]
                []
            ]

        default ->
            [ Html.text ("Timer: " ++ toTimeFormat (ceiling (toFloat model.timeRemaining / 1000))) ]


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
