module Models exposing (Model, Status(..))

import Data.Comment exposing (Comment, Inserted)
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
    , debug : String
    , now : DateTime
    , blogAuthor : String
    , status : Status
    }


type Status
    = Commenting
    | Replying
    | Editing
