port module Ports exposing (..)

{- port for listening for document title from JavaScript -}


port title : (String -> msg) -> Sub msg
