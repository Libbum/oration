module Data.Comment exposing (Comment, Responses, count, decoder, encode, unwrapResponses)

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
    , children : Maybe Responses
    }


type Responses
    = Responses (List Comment)


unwrapResponses : Responses -> List Comment
unwrapResponses responses =
    case responses of
        Responses comments ->
            comments


count : List Comment -> Int
count comments =
    let
        responses =
            List.concatMap (\c -> flatList c) comments
    in
    List.length responses


flatList : Comment -> List Comment
flatList root =
    let
        rest =
            case root.children of
                Just responseList ->
                    List.concatMap (\child -> flatList child) <| unwrapResponses responseList

                Nothing ->
                    []
    in
    root :: rest



-- SERIALIZATION --


decoder : Decoder Comment
decoder =
    decode Comment
        |> required "text" Decode.string
        |> required "author" (Decode.nullable Decode.string)
        |> required "hash" Decode.string
        |> required "created" (Decode.nullable DecodeExtra.date)
        |> required "id" Decode.int
        |> required "children" (Decode.nullable decodeResponses)


decodeResponses : Decoder Responses
decodeResponses =
    Decode.map Responses (Decode.list (Decode.lazy (\_ -> decoder)))


encode : Comment -> Value
encode comment =
    Encode.object
        [ "text" => Encode.string comment.text
        , "author" => EncodeExtra.maybe Encode.string comment.author
        , "hash" => Encode.string comment.hash
        ]
