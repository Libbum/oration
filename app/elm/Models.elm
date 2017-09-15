module Models exposing (..)


type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    , preview : Bool
    , count : Int
    }


initialModel : Model
initialModel =
    Model "" "" "" "" False 0


type alias Changes =
    { name : String
    , email : String
    , url : String
    , preview : Bool
    }
