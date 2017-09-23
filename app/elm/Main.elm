module Main exposing (..)

import Html exposing (..)
import Models exposing (Model)
import Msg exposing (Msg)
import Navigation
import Update exposing (getCount, subscriptions, update)
import View exposing (view)


main =
    Navigation.program Msg.Post { init = init, view = view, update = update, subscriptions = subscriptions }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( { comment = ""
      , name = ""
      , email = ""
      , url = ""
      , preview = False
      , count = 0
      , post = location
      }
    , getCount
    )
