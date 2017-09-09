module Models exposing (..)

type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    , preview : Bool
    }


initialModel : Model
initialModel =
    Model "" "" "" "" False

type alias Changes =
 {
  name : String,
  email : String,
  url : String,
  preview : Bool
 }
