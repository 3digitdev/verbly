module Timer exposing
    ( Action(..)
    , Control(..)
    , Model
    , State(..)
    , fromHours
    , fromMinutes
    , init
    , oneHourMs
    , oneMinuteMs
    , oneSecondMs
    , subs
    , toHours
    , toMinutes
    , update
    , view
    )

import List exposing (map)
import String exposing (fromInt, join)
import Time exposing (every)



-- MODEL


type alias Model =
    { initialTime : Int
    , timeRemaining : Int
    , state : State
    }


type State
    = Running
    | Paused
    | Finished


type Control
    = Countdown
    | DoNothing


type Action
    = NoOp
    | Toggle
    | Reset
    | Tick Time.Posix


init : Int -> Model
init seconds =
    initModel seconds


initModel : Int -> Model
initModel seconds =
    { initialTime = seconds
    , timeRemaining = seconds
    , state = Paused
    }


update : Action -> Model -> Model
update action model =
    case action of
        NoOp ->
            model

        Toggle ->
            { model | state = toggleState model }

        Reset ->
            { model | timeRemaining = model.initialTime }

        Tick _ ->
            model


toggleState : Model -> State
toggleState model =
    case model.state of
        Running ->
            Paused

        Paused ->
            Running

        Finished ->
            model.state


subs : (Time.Posix -> msg) -> Sub msg
subs =
    Time.every 1000



-- case action of
--     Tick ->
--         Time.every 1000 NoOp
--
--     NoOp ->
--         Time.every 1000 NoOp
--
--     default ->
--         Sub.none


{-| Helper Functions for avoiding doing calculations
-}
oneSecondMs : Int
oneSecondMs =
    1000


oneMinuteMs : Int
oneMinuteMs =
    oneSecondMs * 60


oneHourMs : Int
oneHourMs =
    oneMinuteMs * 60


fromHours : Int -> Int
fromHours num =
    num * 60 |> fromMinutes


toHours : Int -> ( Int, Int )
toHours seconds =
    ( seconds |> modBy 36000, seconds |> remainderBy 3600 )


fromMinutes : Int -> Int
fromMinutes num =
    num * 60


toMinutes : Int -> ( Int, Int )
toMinutes seconds =
    ( seconds |> modBy 60, seconds |> remainderBy 60 )


pretty : Int -> String
pretty num =
    if num < 10 then
        "0" ++ fromInt num

    else
        fromInt num


view : Model -> String
view model =
    let
        ( h, r ) =
            model.timeRemaining |> toHours

        ( m, s ) =
            r |> toMinutes
    in
    String.join ":" <| List.map pretty [ h, m, s ]
