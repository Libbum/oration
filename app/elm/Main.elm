module Main exposing (..)

import Html exposing (..)
import Http
import LocalStorage
import Models exposing (Model)
import Msg exposing (Msg)
import Navigation
import Task
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
      , title = ""
      }
    , initialise location
    )


initialise : Navigation.Location -> Cmd Msg
initialise location =
    Cmd.batch
        [ getCount location --TODO: This should be a task.attempt
        , Task.attempt Msg.OnKeys LocalStorage.keys
        ]


getCount : Navigation.Location -> Cmd Msg
getCount location =
    let
        path =
            "/count?url=" ++ location.pathname
    in
    Http.send Msg.Count <|
        Http.getString path
