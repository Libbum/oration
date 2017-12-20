module Main exposing (main)

import Html.Styled exposing (toUnstyled)
import Http
import Models exposing (Model, Status(Commenting))
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
    Navigation.program Msg.Pathname { init = init, view = view >> toUnstyled, update = update, subscriptions = subscriptions }


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
            , identity = ""
            }
      , comments = []
      , count = 0
      , pathname = location.pathname
      , title = ""
      , debug = ""
      , now = dateTime zero
      , editTimeout = 120
      , blogAuthor = ""
      , status = Commenting
      }
    , initialise location.pathname
    )


initialise : String -> Cmd Msg
initialise pathname =
    let
        loadHashes =
            Request.Init.hashes
                |> Http.toTask

        loadComments =
            Request.Comment.comments pathname
                |> Http.toTask
    in
    Cmd.batch
        [ Task.attempt Msg.Hashes loadHashes
        , Task.attempt Msg.Comments loadComments
        , Task.perform Msg.NewDate currentDate
        ]
