module Models exposing (Model, Status(..))

import Data.Comment exposing (Comment, Inserted)
import Data.User exposing (User)
import Time.DateTime exposing (DateTime)


type alias Model =
    { comment : String --TODO: Should probably rename this now
    , parent : Maybe Int
    , user : User
    , comments : List Comment
    , count : Int
    , pathname : String
    , title : String
    , debug : String
    , now : DateTime
    , editTimeout : Float
    , blogAuthor : String
    , status : Status
    }


type Status
    = Commenting
    | Replying
    | Editing
