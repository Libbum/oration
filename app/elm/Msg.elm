module Msg exposing (..)

import Data.Comment exposing (Comment)
import Date exposing (Date)
import Http
import Navigation exposing (Location)
import Time exposing (Time)


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
    | Hash (Result Http.Error String)
    | Comments (Result Http.Error (List Comment))
    | GetDate Time
    | NewDate Date
    | CommentReply Int
