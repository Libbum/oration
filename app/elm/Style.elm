module Style exposing (..)

import Css exposing (..)
import Css.Elements exposing (input, textarea)
import Css.Namespace exposing (namespace)
import Html.CssHelpers exposing (withNamespace)


type OrationClasses
    = Submit
    | Reply
    | Comment
    | Identicon
    | Author
    | Date
    | Content


type OrationIds
    = OrationForm


orationNamespace =
    withNamespace "oration"


css =
    (stylesheet << namespace orationNamespace.name)
        [ class Submit
            [ backgroundColor (hex "ddd")
            , padding (em 0.3)
            , outline zero
            , cursor pointer
            , borderRadius (px 2)
            , border3 (px 1) solid (hex "ccc")
            , boxShadow4 zero (px 1) (px 2) (rgba 0 0 0 0.1)
            , lineHeight (em 1.4)
            ]
        , class Reply
            [ padding (px 20)
            ]
        , class Author
            [ padding (px 2)
            ]
        , class Date
            [ padding (px 3)
            ]
        , class Content
            [ padding (px 1)
            ]
        , class Identicon
            [ margin2 zero (px 10)
            , display inlineBlock
            , verticalAlign middle
            ]
        , id OrationForm
            [ children
                [ each [ input, textarea ]
                    [ padding2 (em 0.3) (px 10)
                    , borderRadius (px 3)
                    , lineHeight (em 1.4)
                    , border3 (px 1) solid (rgba 0 0 0 0.2)
                    , boxShadow4 zero (px 1) (px 2) (rgba 0 0 0 0.1)
                    ]
                ]
            ]
        ]
