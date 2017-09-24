module Msg exposing (..)

import Http
import LocalStorage
import Navigation exposing (Location)


type alias Key =
    LocalStorage.Key


type alias Value =
    LocalStorage.Value


type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview
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
