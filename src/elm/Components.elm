module Components exposing (renderNavBar)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events



{- Nav Bar Header -}


renderNavBar : String -> Html msg
renderNavBar pathPrefix =
    Html.nav []
        [ Html.div
            [ Attributes.class "nav-wrapper indigo" ]
            [ Html.a [ Attributes.href (pathPrefix ++ "/"), Attributes.class "brand-logo center" ]
                [ Html.text "Verbly" ]
            , Html.ul
                [ Attributes.class "left" ]
                [ Html.li []
                    [ Html.a
                        [ Attributes.href (pathPrefix ++ "/TimeAttack") ]
                        [ Html.text "Time Attack" ]
                    ]
                , Html.li []
                    [ Html.a
                        [ Attributes.href (pathPrefix ++ "/Translate") ]
                        [ Html.text "Translate" ]
                    ]
                ]
            ]
        ]
