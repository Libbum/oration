module Models exposing (Model)

import Data.Comment exposing (Comment)
import Data.User exposing (User)
import Navigation exposing (Location)
import Time.Date exposing (Date)


type alias Model =
    { comment : String --TODO: Should probably rename this now
    , parent : Maybe Int
    , user : User
    , comments : List Comment
    , count : Int
    , post : Location
    , title : String
    , httpResponse : String
    , now : Maybe Date
    , blogAuthor : String
    }
