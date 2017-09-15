module Msg exposing (..)

import Http
import Models exposing (Changes)


type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview
    | Count (Result Http.Error String)
