module Components exposing (renderNavBar)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events



{- Nav Bar Header -}


renderNavBar : String -> Html msg
renderNavBar active =
    let
        ( taClass, trClass ) =
            case active of
                "TimeAttack" ->
                    ( "active", "" )

                "Translate" ->
                    ( "", "active" )

                default ->
                    ( "", "" )
    in
    Html.nav [ Attributes.class "big-nav" ]
        [ Html.div
            [ Attributes.class "big-nav nav-wrapper indigo" ]
            [ Html.a [ Attributes.href "/", Attributes.class "app-name brand-logo left" ]
                [ Html.text "Verbly" ]
            , Html.ul
                [ Attributes.class "right" ]
                [ Html.li [ Attributes.class taClass ]
                    [ Html.a
                        [ Attributes.href "TimeAttack.html", Attributes.class "nav-text" ]
                        [ Html.i [ Attributes.class "fn-logo large material-icons left" ] [ Html.text "access_alarm" ]
                        , Html.text "Time Attack"
                        ]
                    ]
                , Html.li [ Attributes.class trClass ]
                    [ Html.a
                        [ Attributes.href "Translate.html", Attributes.class "nav-text" ]
                        [ Html.i [ Attributes.class "fn-logo large material-icons left" ] [ Html.text "translate" ]
                        , Html.text "Translate"
                        ]
                    ]
                ]
            ]
        ]
