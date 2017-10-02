module Msg exposing (..)

import Data.Comment as Comment exposing (Comment)
import Http
import LocalStorage
import Navigation exposing (Location)


type alias Key =
    LocalStorage.Key


type alias Value =
    LocalStorage.Value


type Msg
    = UpdateComment String
    | UpdateName String
    | UpdateEmail String
    | UpdateUrl String
    | UpdatePreview
    | Count (Result Http.Error String)
    | Post Location
    | OnKeys (Result LocalStorage.Error (List Key))
    | SetUser (List Key)
    | OnGet Key (Result LocalStorage.Error (Maybe Value))
    | SetUserValue Key (Maybe Value)
    | OnVoidOp (Result LocalStorage.Error ())
    | Refresh
    | AfterSetValue Key Value (Result LocalStorage.Error ())
    | StoreUser
    | Title String
    | PostComment
    | ReceiveHttp (Result Http.Error String)
    | Hash (Result Http.Error String)
    | Comments (Result Http.Error (List Comment))
