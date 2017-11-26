module Util exposing ((=>), nothing, pair, parseMath, stringToMaybe, viewKatex)

import Html exposing (Html, div, span, text)
import Katex exposing (Latex, display, human, inline)
import Maybe.Extra exposing ((?))
import Regex exposing (regex, replace, split)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


{-| infixl 0 means the (=>) operator has the same precedence as (<|) and (|>),
meaning you can use it at the end of a pipeline and have the precedence work out.
-}
infixl 0 =>


{-| Useful when building up a Cmd via a pipeline, and then pairing it with
a model at the end.
session.user
|> User.Request.foo
|> Task.attempt Foo
|> pair { model | something = blah }
-}
pair : a -> b -> ( a, b )
pair first second =
    first => second


stringToMaybe : String -> Maybe String
stringToMaybe val =
    if String.isEmpty val then
        Nothing
    else
        Just val


nothing : Html msg
nothing =
    text ""



{- Identify math strings and use Katex to parse them.
   Note, we still return a string here rather than HTML, since this
   will go through the markdown parser next, which handles raw HTML.
-}


parseMath : String -> List (Html msg)
parseMath data =
    let
        inlines =
            parseInline data
    in
    List.map viewKatex inlines


parseDisplay : List String -> List String
parseDisplay =
    List.map (replace (Regex.AtMost 1) (regex "^\\${2}(.+?)\\${2}") separateDisplay)


separateDisplay : Regex.Match -> String
separateDisplay match =
    let
        result =
            (List.head match.submatches ? Just "") ? ""
    in
    Katex.print (display result)


parseInline : String -> List (List Latex)
parseInline data =
    let
        inlines =
            findInlines data
    in
    List.map (\results -> separateInline results data) inlines


findInlines : String -> List Regex.Match
findInlines =
    Regex.find Regex.All (regex "\\$([^\\$]+?)\\$(?!\\$)")


separateInline : Regex.Match -> String -> List Latex
separateInline match data =
    let
        begin =
            String.left match.index data

        matched =
            (List.head match.submatches ? Just "") ? ""

        end =
            String.right (match.index + String.length match.match) data
    in
    [ human begin
    , inline matched
    ]


passage : List Latex
passage =
    [ human "We denote by "
    , inline "\\phi"
    , human " the formula for which "
    , display "\\Gamma \\vDash \\phi"
    ]


viewKatex : List Latex -> Html msg
viewKatex result =
    let
        htmlGenerator isDisplayMode stringLatex =
            case isDisplayMode of
                Just True ->
                    div [] [ text stringLatex ]

                _ ->
                    span [] [ text stringLatex ]
    in
    result
        |> List.map (Katex.generate htmlGenerator)
        |> div []
