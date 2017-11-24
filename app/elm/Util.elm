module Util exposing ((=>), nothing, pair, parseMath, stringToMaybe)

import Html exposing (Html, text)
import Katex exposing (Latex, display, human, inline)
import Maybe.Extra exposing ((?))
import Regex exposing (regex, replace)


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


parseMath : String -> String
parseMath =
    parseInline


parseDisplay : String -> String
parseDisplay =
    replace Regex.All (regex "^\\$\\$(.+?)\\$\\$") separateDisplay


separateDisplay : Regex.Match -> String
separateDisplay match =
    let
        result =
            (List.head match.submatches ? Just "") ? ""
    in
    Katex.print (display result)


parseInline : String -> String
parseInline =
    replace Regex.All (regex "\\$(?!\\$)(.+?)\\$(?!\\$)") separateInline


separateInline : Regex.Match -> String
separateInline match =
    let
        result =
            (List.head match.submatches ? Just "") ? ""
    in
    Katex.print (inline result)
