module Models exposing (..)

import Dict exposing (Dict)
import LocalStorage
import Navigation exposing (Location)


type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    , preview : Bool
    , count : Int
    , post : Location
    , keys : List LocalStorage.Key -- all keys in LocalStorage
    , values : Dict LocalStorage.Key LocalStorage.Value -- a shadow of the keys and values in LocalStorage
    , errors : List LocalStorage.Error
    }
