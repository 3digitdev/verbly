module Home exposing (main)

import Browser
import Components
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes


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
    {}



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Html.div
        []
        -- [ Html.node "link"
        --     [ Attributes.rel "stylesheet"
        --     , Attributes.href "../../public/stylesheets/main.css"
        --     ]
        --     []
        [ Components.renderNavBar "Home"
        , Html.div
            [ Attributes.class "header-container" ]
            [ Html.div
                [ Attributes.class "subject-container center-block" ]
                [ Html.h1
                    [ Attributes.class "center" ]
                    [ Html.text "Welcome To Verbly!" ]
                , Html.h2
                    [ Attributes.class "center" ]
                    [ Html.text "Select a function to try out!" ]
                , renderFunctionButtons
                ]
            ]
        ]


renderFunctionButtons : Html Msg
renderFunctionButtons =
    Html.div
        [ Attributes.class "row" ]
        [ Html.div
            [ Attributes.class "col s4 push-s2" ]
            [ Html.a
                [ Attributes.href "TimeAttack.html", Attributes.class "btn-large indigo white-text" ]
                [ Html.text "Time Attack" ]
            ]
        , Html.div
            [ Attributes.class "col s4 push-s3" ]
            [ Html.a
                [ Attributes.href "Translate.html", Attributes.class "btn-large indigo white-text" ]
                [ Html.text "Translate" ]
            ]
        ]
