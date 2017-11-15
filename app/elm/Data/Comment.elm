module Data.Comment exposing (Comment, Responses(Responses), count, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Time.DateTime exposing (DateTime)
import Util exposing ((=>))


type alias Comment =
    { text : String
    , author : Maybe String
    , hash : String
    , created : DateTime
    , id : Int
    , children : Responses
    }


type Responses
    = Responses (List Comment)



{- TOTAL COUNT -}


count : List Comment -> Int
count =
    foldl (\_ acc -> acc + 1) 0


foldl : (Comment -> b -> b) -> b -> List Comment -> b
foldl f =
    List.foldl
        (\c acc ->
            case c.children of
                Responses responses ->
                    foldl f (f c acc) responses
        )



{- SERIALIZATION -}


decoder : Decoder Comment
decoder =
    decode Comment
        |> required "text" Decode.string
        |> required "author" (Decode.nullable Decode.string)
        |> required "hash" Decode.string
        |> required "created" decodeDate
        |> required "id" Decode.int
        |> required "children" decodeResponses


decodeResponses : Decoder Responses
decodeResponses =
    Decode.map Responses (Decode.list (Decode.lazy (\_ -> decoder)))


decodeDate : Decoder DateTime
decodeDate =
    Decode.string
        |> Decode.andThen (Time.DateTime.fromISO8601 >> DecodeExtra.fromResult)


encode : Comment -> Value
encode comment =
    Encode.object
        [ "text" => Encode.string comment.text
        , "author" => EncodeExtra.maybe Encode.string comment.author
        , "hash" => Encode.string comment.hash
        ]
