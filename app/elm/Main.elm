module Main exposing (..)

import Html exposing (..)
import Http
import Models exposing (Model)
import Msg exposing (Msg)
import Navigation
import Update exposing (subscriptions, update)
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
    , getCount location
    )

getCount : Navigation.Location -> Cmd Msg
getCount location =
    let
        path = "/count?url=" ++ location.pathname
    in
    Http.send Msg.Count <|
        Http.getString path
