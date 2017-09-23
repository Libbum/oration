module Msg exposing (..)

import Models exposing (Changes)
import Navigation exposing (Location)


type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview
    | Post Location
