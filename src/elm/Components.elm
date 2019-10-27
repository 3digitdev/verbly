module Components exposing (renderNavBar)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events



{- Nav Bar Header -}


renderNavBar : Html msg
renderNavBar =
    Html.nav []
        [ Html.div
            [ Attributes.class "nav-wrapper indigo" ]
            [ Html.a [ Attributes.href "/", Attributes.class "brand-logo center" ]
                [ Html.text "Verbly" ]
            , Html.ul
                [ Attributes.class "left" ]
                [ Html.li []
                    [ Html.a
                        [ Attributes.href "/TimeAttack" ]
                        [ Html.text "Time Attack" ]
                    ]
                , Html.li []
                    [ Html.a
                        [ Attributes.href "/Translate" ]
                        [ Html.text "Translate" ]
                    ]
                ]
            ]
        ]
