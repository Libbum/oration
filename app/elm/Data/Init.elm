module Data.Init exposing (Init, decoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required)


type alias Init =
    { userIp : Maybe String
    , blogAuthor : Maybe String
    , editTimeout : Float
    }



-- SERIALIZATION --


decoder : Decoder Init
decoder =
    decode Init
        |> required "user_ip" (Decode.nullable Decode.string)
        |> required "blog_author" (Decode.nullable Decode.string)
        |> required "edit_timeout" Decode.float
