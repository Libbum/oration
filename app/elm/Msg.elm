module Msg exposing (..)

import Http
import Models exposing (Changes)
import Navigation exposing (Location)



type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview
    | Count (Result Http.Error String)
    | Post Location
