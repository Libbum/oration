module Util exposing ((=>), delay, nothing, pair, stringToMaybe)

import Html.Styled exposing (Html, text)
import Process
import Task
import Time exposing (Time)


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



{- Invoke a time delay for an action -}


delay : Time -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.andThen (always <| Task.succeed msg)
        |> Task.perform identity
