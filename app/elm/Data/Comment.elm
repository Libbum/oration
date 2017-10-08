module Data.Comment exposing (Comment, decoder, encode)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Util exposing ((=>))


type alias Comment =
    { text : String
    , author : Maybe String
    , hash : String
    , created : Maybe Date
    , id : Int
    , parent : Maybe Int
    }



-- SERIALIZATION --


decoder : Decoder Comment
decoder =
    decode Comment
        |> required "text" Decode.string
        |> required "author" (Decode.nullable Decode.string)
        |> required "hash" Decode.string
        |> required "created" (Decode.nullable DecodeExtra.date)
        |> required "id" Decode.int
        |> required "parent" (Decode.nullable Decode.int)


encode : Comment -> Value
encode comment =
    Encode.object
        [ "text" => Encode.string comment.text
        , "author" => EncodeExtra.maybe Encode.string comment.author
        , "hash" => Encode.string comment.hash
        , "parent" => EncodeExtra.maybe Encode.int comment.parent
        ]
