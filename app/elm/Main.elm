module Main exposing (main)

import Date
import Http
import LocalStorage
import Models exposing (Model)
import Msg exposing (Msg)
import Navigation
import Request.Comment
import Request.User
import Task
import Update exposing (subscriptions, update)
import View exposing (view)


main : Program Never Model Msg
main =
    Navigation.program Msg.Post { init = init, view = view, update = update, subscriptions = subscriptions }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( { comment = ""
      , parent = Nothing
      , user =
            { name = Nothing
            , email = Nothing
            , url = Nothing
            , preview = False
            , iphash = Nothing
            }
      , comments = []
      , count = 0
      , post = location
      , title = ""
      , httpResponse = ""
      , now = Nothing
      }
    , initialise location
    )


initialise : Navigation.Location -> Cmd Msg
initialise location =
    let
        --TODO: Count wont be needed soon, not on the main view at least.
        loadCount =
            Request.Comment.count location
                |> Http.toTask

        loadHash =
            Request.User.hash
                |> Http.toTask

        loadComments =
            Request.Comment.comments location
                |> Http.toTask
    in
    Cmd.batch
        [ Task.attempt Msg.Count loadCount
        , Task.attempt Msg.OnKeys LocalStorage.keys
        , Task.attempt Msg.Hash loadHash
        , Task.attempt Msg.Comments loadComments
        , Task.perform Msg.ReceiveDate Date.now
        ]
