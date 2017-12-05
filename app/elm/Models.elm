module Models exposing (Model)

import Data.Comment exposing (Comment)
import Data.User exposing (User)
import Navigation exposing (Location)
import Time.DateTime exposing (DateTime)


type alias Model =
    { comment : String --TODO: Should probably rename this now
    , parent : Maybe Int
    , user : User
    , comments : List Comment
    , count : Int
    , post : Location
    , title : String
    , postResponse : String
    , now : DateTime
    , blogAuthor : String
    }
