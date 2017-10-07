module Models exposing (Model)

import Data.Comment exposing (Comment)
import Data.User exposing (User)
import Date exposing (Date)
import Navigation exposing (Location)


type alias Model =
    { comment : String --TODO: Should probably rename this now
    , user : User
    , comments : List Comment
    , count : Int
    , post : Location
    , title : String
    , httpResponse : String
    , now : Maybe Date
    }
