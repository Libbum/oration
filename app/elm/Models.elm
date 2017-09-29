module Models exposing (..)

import Data.User as User exposing (User)
import Navigation exposing (Location)


type alias Model =
    { comment : String
    , user : User
    , count : Int
    , post : Location
    , title : String
    , httpResponse : String
    }
