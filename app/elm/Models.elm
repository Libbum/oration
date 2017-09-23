module Models exposing (..)

import Navigation exposing (Location)


type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    , preview : Bool
    , post : Location
    }


type alias Changes =
    { name : String
    , email : String
    , url : String
    , preview : Bool
    }
