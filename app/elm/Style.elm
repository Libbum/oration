module Style exposing (OrationClasses(..), OrationIds(..), activeColor, clickableStyle, css, hoverColor, inputStyle, orationNamespace, primaryColor)

import Css exposing (..)
import Css.Elements exposing (button, img, input, label, li, p, textarea, typeSelector)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace)


type OrationClasses
    = Submit
    | Footer
    | Response
    | Thread
    | BlogAuthor
    | Identicon
    | Author
    | Deleted
    | Date
    | Comment
    | Content
    | Form
    | Spacer
    | User
    | Control
    | Block
    | LeftMargin10
    | Hidden
    | Toggle
    | Votes


type OrationIds
    = Oration
    | OrationComments
    | OrationForm
    | OrationReplyForm
    | OrationPreviewCheck
    | OrationCommentPreview


orationNamespace : Html.CssHelpers.Namespace String class id msg
orationNamespace =
    withNamespace "oration"



{- Colors -}


primaryColor : Color
primaryColor =
    hex "6496c8"


hoverColor : Color
hoverColor =
    hex "346392"


activeColor : Color
activeColor =
    hex "27496d"


css : Stylesheet
css =
    (stylesheet << namespace orationNamespace.name)
        [ class Submit
            [ color (hex "fff")
            , textShadow3 (px -2) (px -2) hoverColor
            , backgroundColor (hex "ff9664")
            , backgroundImage (linearGradient2 toTop (stop primaryColor) (stop hoverColor) [])
            , cursor pointer
            , borderRadius (px 15)
            , border zero
            , boxShadow6 inset zero zero zero (px 1) activeColor
            , hover [ property "box-shadow" "inset 0 0 0 1px #27496d,0 5px 15px #193047" ]
            , active [ property "box-shadow" "inset 0 0 0 1px #27496d,0 5px 30px #193047" ]
            , disabled [ color (hex "ccc") ]
            , padding2 (px 10) (px 20)
            , marginLeft (px 20)
            ]
        , class Footer
            [ children
                [ button
                    [ clickableStyle
                    , border3 (px 1) solid primaryColor
                    , borderRadius (px 15)
                    , marginBottom (px 10)
                    , marginRight (px 10)
                    , fontSize (pt 10)
                    , disabled
                        [ cursor default
                        , color (hex "ccc")
                        ]
                    ]
                ]
            ]
        , class Votes
            [ color primaryColor
            , marginRight (px 10)
            , children
                [ button
                    [ clickableStyle
                    , border3 (px 1) solid primaryColor
                    , borderRadius (px 15)
                    , fontSize (pt 10)
                    , disabled
                        [ cursor default
                        , color (hex "ccc")
                        ]
                    ]
                ]
            ]
        , class Response
            [ paddingLeft (px 20)
            , border3 (px 1) solid (hex "F00")
            ]
        , class Control
            [ float right
            , display block
            , marginBottom (px 5)
            ]
        , class Block
            [ display block
            ]
        , class Hidden
            [ display none
            ]
        , class Toggle
            [ clickableStyle
            , border zero
            ]
        , class BlogAuthor
            [ backgroundColor (rgba 0 0 0 0.03) ]
        , class Author
            [ fontWeight bold
            , color (hex "555")
            ]
        , class Deleted
            [ fontStyle italic
            , color (hex "555")
            , padding2 zero (px 6)
            , marginBottom (px 10)
            , display inlineBlock
            ]
        , each [ class Date, class Spacer ]
            [ color (hex "666")
            , fontWeight normal
            , textShadow none
            ]
        , class Spacer
            [ padding2 zero (px 6)
            ]
        , class Content
            [ padding (px 0)
            , children
                [ p
                    [ firstOfType
                        [ marginTop (em 0.5) ]
                    , lastOfType
                        [ marginBottom (em 0.25) ]
                    ]
                ]
            , descendants
                [ img
                    [ maxWidth (pct 100)
                    ]
                , Css.Elements.pre
                    [ overflowX auto
                    ]
                ]
            ]
        , class Comment
            [ padding (px 0) ]
        , class Identicon
            [ display inlineBlock
            , verticalAlign middle
            , marginRight (px 10)
            ]
        , class LeftMargin10
            [ marginLeft (px 10)
            ]
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
        , class Form
            [ children
                [ textarea [ inputStyle ]
                ]
            , margin3 zero auto (px 10)
            , float left
            ]
        , class User
            [ paddingTop (px 2)
            , paddingBottom (px 5)
            , children
                [ input
                    [ inputStyle
                    , width (px 162)
                    ]
                ]
            ]
        , Css.Elements.code
            [ fontSize (px 14)
            ]
        , id OrationComments
            [ padding zero
            , children
                [ li
                    [ firstChild
                        [ border zero
                        ]
                    ]
                ]
            ]
        , li
            [ listStyleType none
            , borderTop3 (px 1) solid (rgba 0 0 0 0.2)
            , paddingTop (px 5)
            ]
        , id Oration
            [ width (px 597)
            ]
        ]


inputStyle : Style
inputStyle =
    batch
        [ padding2 (em 0.3) (px 10)
        , borderRadius (px 3)
        , lineHeight (em 1.4)
        , border3 (px 1) solid (rgba 0 0 0 0.2)
        , boxShadow4 zero (px 1) (px 2) (rgba 0 0 0 0.1)
        ]


clickableStyle : Style
clickableStyle =
    batch
        [ backgroundColor (rgba 0 0 0 0)
        , color primaryColor
        , cursor pointer
        , outline zero
        , hover [ borderColor hoverColor, color hoverColor ]
        , active [ borderColor activeColor, color activeColor ]
        ]
