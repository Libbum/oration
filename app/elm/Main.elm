module Main exposing (..)

import Html exposing (..)
import Models exposing (initialModel)
import Update exposing (update, subscriptions)
import View exposing (view)


main =
    Html.program { init = (initialModel, Cmd.none), view = view, update = update, subscriptions = subscriptions }

