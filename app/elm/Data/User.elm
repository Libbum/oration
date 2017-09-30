module Data.User exposing (User, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Util exposing ((=>))


type alias User =
    { name : Maybe String
    , email : Maybe String
    , url : Maybe String
    , iphash : Maybe String
    , preview : Bool
    }



-- SERIALIZATION --


decoder : Decoder User
decoder =
    decode User
        |> required "name" (Decode.nullable Decode.string)
        |> required "email" (Decode.nullable Decode.string)
        |> required "url" (Decode.nullable Decode.string)
        |> required "iphash" (Decode.nullable Decode.string)
        |> required "preview" Decode.bool


encode : User -> Value
encode user =
    Encode.object
        [ "name" => EncodeExtra.maybe Encode.string user.name
        , "email" => EncodeExtra.maybe Encode.string user.email
        , "url" => EncodeExtra.maybe Encode.string user.url
        , "iphash" => EncodeExtra.maybe Encode.string user.iphash
        , "preview" => Encode.bool user.preview
        ]
