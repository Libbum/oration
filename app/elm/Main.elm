module Main exposing (..)

import Html exposing (..)
import Models exposing (initialModel)
import Update exposing (getCount, subscriptions, update)
import View exposing (view)


main =
    Html.program { init = ( initialModel, getCount ), view = view, update = update, subscriptions = subscriptions }
