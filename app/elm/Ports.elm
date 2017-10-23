port module Ports exposing (title)

{- port for listening for document title from JavaScript -}


port title : (String -> msg) -> Sub msg
