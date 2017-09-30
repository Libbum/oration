module Models exposing (..)

import Data.Comment as Comment exposing (Comment)
import Data.User as User exposing (User)
import Navigation exposing (Location)


type alias Model =
    { comment : String --TODO: Should probably rename this now
    , user : User
    , comments : List Comment
    , count : Int
    , post : Location
    , title : String
    , httpResponse : String
    }
