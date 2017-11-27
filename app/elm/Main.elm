module Main exposing (main)

import Http
import Models exposing (Model)
import Msg exposing (Msg)
import Navigation
import Request.Comment
import Request.Init
import Task
import Time.DateTime exposing (dateTime, zero)
import Update exposing (currentDate, subscriptions, update)
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
      , now = dateTime zero
      , blogAuthor = ""
      , math = ""
      }
    , initialise location
    )


initialise : Navigation.Location -> Cmd Msg
initialise location =
    let
        loadHashes =
            Request.Init.hashes
                |> Http.toTask

        loadComments =
            Request.Comment.comments location
                |> Http.toTask
    in
    Cmd.batch
        [ Task.attempt Msg.Hashes loadHashes
        , Task.attempt Msg.Comments loadComments
        , Task.perform Msg.NewDate currentDate
        ]
