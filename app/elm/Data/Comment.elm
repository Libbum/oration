module Data.Comment exposing (Comment, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Util exposing ((=>))


type alias Comment =
    { text : String
    , author : Maybe String
    , hash : String
    }



-- SERIALIZATION --


decoder : Decoder Comment
decoder =
    decode Comment
        |> required "text" Decode.string
        |> required "author" (Decode.nullable Decode.string)
        |> required "hash" Decode.string


encode : Comment -> Value
encode comment =
    Encode.object
        [ "text" => Encode.string comment.text
        , "author" => EncodeExtra.maybe Encode.string comment.author
        , "hash" => Encode.string comment.hash
        ]
