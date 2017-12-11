module Data.User exposing (User, decoder, encode, getIdentity)

import Crypto.Hash
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, optional, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Maybe.Extra exposing ((?), isNothing)
import Util exposing ((=>))


type alias User =
    { name : Maybe String
    , email : Maybe String
    , url : Maybe String
    , iphash : Maybe String
    , preview : Bool
    , identity : String
    }



{- Hashes user information depending on available data -}


getIdentity : User -> String
getIdentity user =
    let
        data =
            [ user.name, user.email, user.url ]

        --I think Maybe.Extra.values could also be used here
        unwrapped =
            List.filterMap identity data
    in
    if List.all isNothing data then
        user.iphash ? ""
    else
        -- Join with b since it gives the authors' credentials a cool identicon
        Crypto.Hash.sha224 (String.join "b" unwrapped)



-- SERIALIZATION --


decoder : Decoder User
decoder =
    decode User
        |> required "name" (Decode.nullable Decode.string)
        |> required "email" (Decode.nullable Decode.string)
        |> required "url" (Decode.nullable Decode.string)
        |> required "iphash" (Decode.nullable Decode.string)
        |> required "preview" Decode.bool
        |> optional "identity" Decode.string ""


encode : User -> Value
encode user =
    Encode.object
        [ "name" => EncodeExtra.maybe Encode.string user.name
        , "email" => EncodeExtra.maybe Encode.string user.email
        , "url" => EncodeExtra.maybe Encode.string user.url
        , "iphash" => EncodeExtra.maybe Encode.string user.iphash
        , "preview" => Encode.bool user.preview
        , "identity" => Encode.string user.identity
        ]
