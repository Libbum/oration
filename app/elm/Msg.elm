module Msg exposing (..)

import Data.Comment exposing (Comment)
import Data.Init exposing (Init)
import Http
import Navigation exposing (Location)
import Time exposing (Time)
import Time.Date exposing (Date)


type Msg
    = UpdateComment String
    | UpdateName String
    | UpdateEmail String
    | UpdateUrl String
    | UpdatePreview
    | SetPreview String
    | Count (Result Http.Error String)
    | Post Location
    | StoreUser
    | Title String
    | PostComment
    | ReceiveHttp (Result Http.Error String)
    | Hashes (Result Http.Error Init)
    | Comments (Result Http.Error (List Comment))
    | GetDate Time
    | NewDate Date
    | CommentReply Int
