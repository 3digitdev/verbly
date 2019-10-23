module TimeAttack exposing (main)

import Api
import Browser
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
        --( btnState, btnClass ) =
        --    case model.state of
        --        Paused ->
        --            ( "Start", "-show" )

        --        Running ->
        --            ( "Stop", "-show" )

        --        Finished ->
        --            ( "Restart", "" )

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
        , renderNavBar model
        , Html.div [ Attributes.class "sidebar-container" ]
            [ Html.div [] [ Html.h3 [ Attributes.class "noBtMrgn" ] [ Html.text "Timer" ] ]
            , Html.div
                []
                [ Html.h1 [ Attributes.class "timer-text" ] [ Html.text (fromInt (ceiling (toFloat model.timeRemaining / 1000))) ] ]
            , Html.div
                []
                [ Html.div []
                    [ Html.h1 [ Attributes.class "score-text green-text darken-2" ] [ Html.text ("Right: " ++ fromInt model.correctAnswers) ]
                    , Html.h1 [ Attributes.class "score-text red-text darken-2" ] [ Html.text ("Wrong: " ++ fromInt model.wrongAnswers) ]
                    ]
                ]
            ]
        , Html.div [ Attributes.class "header-container" ]
            [ Html.div [ Attributes.class "subject-container center-block" ] [ Html.h1 [ Attributes.class "center" ] [ Html.text header ] ] ]
        , Html.div
            [ Attributes.class "container center-block" ]
            [ renderOutput model ]
        ]


timeToSeconds : Int -> String
timeToSeconds ms =
    fromInt (ceiling (toFloat ms / 1000))


renderOutput : Model -> Html Msg
renderOutput model =
    case model.currentVerb of
        Resp val ->
            Html.div [ Attributes.class "content-container" ]
                (renderQuestion model val)

        Empty ->
            Html.div [ Attributes.class "content-container" ]
                [ Html.button
                    [ Attributes.class "waves-effect waves-light btn-large xl-button orange darken-3"
                    , Events.onClick Reset
                    ]
                    [ Html.text "Restart" ]
                ]


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


iconIndex : Int -> String
iconIndex idx =
    case idx of
        1 ->
            "one"

        2 ->
            "two"

        _ ->
            fromInt idx



{- Nav Bar -}


renderNavBar : Model -> Html Msg
renderNavBar model =
    Html.nav []
        [ Html.div
            [ Attributes.class "nav-wrapper indigo" ]
            [ Html.a [ Attributes.href "#", Attributes.class "brand-logo center" ]
                [ Html.text "Verbly" ]
            , Html.ul
                [ Attributes.class "left" ]
                [ Html.li [] [ Html.a [ Attributes.href "#" ] [ Html.text "Practice" ] ]
                , Html.li [] [ Html.a [ Attributes.href "#" ] [ Html.text "Translate" ] ]
                ]
            ]
        ]
