module Msg exposing (..)

import Data.Comment exposing (Comment, Inserted)
import Data.Init exposing (Init)
import Http
import Navigation exposing (Location)
import Time exposing (Time)
import Time.DateTime exposing (DateTime)


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
    | PostConfirm (Result Http.Error Inserted)
    | Hashes (Result Http.Error Init)
    | Comments (Result Http.Error (List Comment))
    | GetDate Time
    | NewDate DateTime
    | CommentReply Int
    | CommentEdit Int
    | CommentDelete Int
    | EditConfirm (Result Http.Error String)
    | DeleteConfirm (Result Http.Error Int)
    | ToggleCommentVisibility Int
