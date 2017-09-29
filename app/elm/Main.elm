module Main exposing (..)

import Http
import LocalStorage
import Models exposing (Model)
import Msg exposing (Msg)
import Navigation
import Request.Comment
import Task
import Update exposing (subscriptions, update)
import View exposing (view)


main : Program Never Model Msg
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
      , httpResponse = ""
      }
    , initialise location
    )


initialise : Navigation.Location -> Cmd Msg
initialise location =
    let
        loadCount =
            Request.Comment.count location
                |> Http.toTask
    in
    Cmd.batch
        [ Task.attempt Msg.Count loadCount
        , Task.attempt Msg.OnKeys LocalStorage.keys
        ]
