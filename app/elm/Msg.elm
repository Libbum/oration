module Msg exposing (..)

import Models exposing (Changes)

type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview


