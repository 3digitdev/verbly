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
    Html.nav []
        [ Html.div
            [ Attributes.class "nav-wrapper indigo" ]
            [ Html.a [ Attributes.href "/", Attributes.class "brand-logo center" ]
                [ Html.text "Verbly" ]
            , Html.ul
                [ Attributes.class "left" ]
                [ Html.li [ Attributes.class taClass ]
                    [ Html.a
                        [ Attributes.href "/TimeAttack" ]
                        [ Html.text "Time Attack" ]
                    ]
                , Html.li [ Attributes.class trClass ]
                    [ Html.a
                        [ Attributes.href "/Translate" ]
                        [ Html.text "Translate" ]
                    ]
                ]
            ]
        ]
