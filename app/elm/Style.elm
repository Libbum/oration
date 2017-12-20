module Style exposing (..)

import Css exposing (..)
import Css.Foreign exposing (children, descendants, id, typeSelector)
import Html.Styled exposing (..)


{-| A plain old record holding a couple of theme colors.
-}
theme : { active : Color, hover : Color, primary : Color }
theme =
    { primary = hex "6496c8"
    , active = hex "27496d"
    , hover = hex "346392"
    }


footerButton : List (Attribute msg) -> List (Html msg) -> Html msg
footerButton =
    styled button
        [ clickableStyle
        , border3 (px 1) solid theme.primary
        , borderRadius (px 15)
        , marginBottom (px 10)
        , marginRight (px 10)
        , fontSize (pt 10)
        , disabled
            [ cursor default
            , color (hex "ccc")
            ]
        ]


commentArea : List (Attribute msg) -> List (Html msg) -> Html msg
commentArea =
    styled textarea
        [ inputStyle
        , display block
        ]


userInput : List (Attribute msg) -> List (Html msg) -> Html msg
userInput =
    styled input
        [ inputStyle
        , width (px 162)
        ]


clickableStyle : Style
clickableStyle =
    batch
        [ backgroundColor (rgba 0 0 0 0)
        , color theme.primary
        , cursor pointer
        , outline zero
        , hover [ borderColor theme.hover, color theme.hover ]
        , active [ borderColor theme.active, color theme.active ]
        ]


inputStyle : Style
inputStyle =
    batch
        [ padding2 (Css.em 0.3) (px 10)
        , borderRadius (px 3)
        , lineHeight (Css.em 1.4)
        , border3 (px 1) solid (rgba 0 0 0 0.2)
        , boxShadow4 zero (px 1) (px 2) (rgba 0 0 0 0.1)
        ]


votes : List Style
votes =
    [ color theme.primary
    , marginRight (px 10)
    ]


author : List Style
author =
    [ fontWeight bold
    , color (hex "555")
    ]


response : List Style
response =
    [ paddingLeft (px 20)
    , border3 (px 1) solid (hex "F00")
    ]


submit : List Style
submit =
    [ color (hex "fff")
    , textShadow3 (px -2) (px -2) theme.hover
    , backgroundColor (hex "ff9664")
    , backgroundImage (linearGradient2 toTop (stop theme.primary) (stop theme.hover) [])
    , cursor pointer
    , borderRadius (px 15)
    , border zero
    , boxShadow6 inset zero zero zero (px 1) theme.active
    , hover [ property "box-shadow" "inset 0 0 0 1px #27496d,0 5px 15px #193047" ]
    , active [ property "box-shadow" "inset 0 0 0 1px #27496d,0 5px 30px #193047" ]
    , disabled [ color (hex "ccc") ]
    , padding2 (px 10) (px 20)
    , marginLeft (px 20)
    ]


control : List Style
control =
    [ float right
    , display block
    , marginBottom (px 5)
    ]


hidden : List Style
hidden =
    [ display none
    ]


toggle : List Style
toggle =
    [ clickableStyle
    , border zero
    ]


blogAuthor : List Style
blogAuthor =
    [ backgroundColor (rgba 0 0 0 0.03) ]


deleted : List Style
deleted =
    [ fontStyle italic
    , color (hex "555")
    , padding2 zero (px 6)
    , marginBottom (px 10)
    , display inlineBlock
    ]


date : List Style
date =
    [ color (hex "666")
    , fontWeight normal
    , textShadow none
    ]


spacer : List Style
spacer =
    [ padding2 zero (px 6)
    , color (hex "666")
    , fontWeight normal
    , textShadow none
    ]


content : List Style
content =
    [ padding (px 0)
    , children
        [ Css.Foreign.p
            [ firstOfType
                [ marginTop (Css.em 0.5) ]
            , lastOfType
                [ marginBottom (Css.em 0.25) ]
            ]
        ]
    , descendants
        [ Css.Foreign.img
            [ maxWidth (pct 100)
            ]
        , Css.Foreign.pre
            [ overflowX auto
            ]
        ]
    ]


comment : List Style
comment =
    [ padding (px 0) ]


identicon : List Style
identicon =
    [ display inlineBlock
    , verticalAlign middle
    , marginRight (px 10)
    ]


leftMargin10 : List Style
leftMargin10 =
    [ marginLeft (px 10)
    ]


form : List Style
form =
    [ margin3 zero auto (px 10)
    , float left
    ]


user : List Style
user =
    [ paddingTop (px 2)
    , paddingBottom (px 5)
    ]


oration : List Style
oration =
    [ width (px 597)
    ]


orationComments : List Style
orationComments =
    [ padding zero
    , children
        [ Css.Foreign.li
            [ firstChild
                [ border zero
                ]
            ]
        ]
    ]



{-
   , typeSelector "input[type=\"checkbox\"]"
       [ adjacentSiblings
           [ label
               [ lastChild
                   [ marginBottom zero ]
               , before
                   [ display inlineBlock
                   , property "content" "''"
                   , width (px 20)
                   , height (px 20)
                   , border3 (px 1) solid (rgba 0 0 0 0.5)
                   , position absolute
                   , left (px 5)
                   , top zero
                   , opacity (num 0.6)
                   , property "-webkit-transition" "all .12s, border-color .08s"
                   , property "transition" "all .12s, border-color .08s"
                   ]
               , display inlineBlock
               , position relative
               , paddingLeft (px 30)
               , cursor pointer
               , property "-webkit-user-select" "none"
               , property "-moz-user-select" "none"
               , property "-ms-user-select" "none"
               ]
           ]
       , display none
       , checked
           [ adjacentSiblings
               [ label
                   [ before
                       [ width (px 10)
                       , top (px -5)
                       , left (px 10)
                       , borderRadius zero
                       , opacity (int 1)
                       , borderTopColor transparent
                       , borderLeftColor transparent
                       , transform (rotate (deg 45))
                       , property "-webkit-transform" "rotate(45deg)"
                       ]
                   ]
               ]
           ]
       ]
   , Css.Elements.code
       [ fontSize (px 14)
   , li
       [ listStyleType none
       , borderTop3 (px 1) solid (rgba 0 0 0 0.2)
       , paddingTop (px 5)
       ]
   ]



-}
