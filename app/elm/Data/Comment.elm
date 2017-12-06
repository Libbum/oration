module Data.Comment exposing (Comment, Inserted, Responses(Responses), count, decoder, encode, insertDecoder, insertNew, toggleVisible)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline exposing (decode, hardcoded, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Maybe.Extra exposing ((?), isNothing)
import Time.DateTime exposing (DateTime)
import Util exposing ((=>))


type alias Comment =
    { text : String
    , author : Maybe String
    , hash : String
    , created : DateTime
    , id : Int
    , children : Responses
    , visible : Bool
    , editable : Bool
    }


type Responses
    = Responses (List Comment)


type alias Inserted =
    { id : Int
    , parent : Maybe Int
    , author : Maybe String
    }



{- TOTAL COUNT -}


count : List Comment -> Int
count =
    foldl (\_ acc -> acc + 1) 0



{- STRUCTURE UPDATES -}


insertNew : Inserted -> ( String, String, DateTime, List Comment ) -> List Comment
insertNew insert current =
    let
        ( commentText, hash, now, comments ) =
            current

        newComment =
            { text = commentText
            , author = insert.author
            , hash = hash
            , created = now
            , id = insert.id
            , children = Responses []
            , visible = True
            , editable = True
            }
    in
    if isNothing insert.parent then
        comments ++ List.singleton newComment
    else
        List.map (\comment -> injectNew insert newComment comment) comments


injectNew : Inserted -> Comment -> Comment -> Comment
injectNew insert newComment comment =
    let
        children =
            if comment.id == insert.parent ? -1 then
                case comment.children of
                    Responses responses ->
                        Responses <| responses ++ List.singleton newComment
            else
                case comment.children of
                    Responses responses ->
                        Responses <| List.map (\response -> injectNew insert newComment response) responses
    in
    { comment | children = children }


toggleVisible : Int -> List Comment -> List Comment
toggleVisible id comments =
    List.map (\comment -> switchVisible id comment) comments


switchVisible : Int -> Comment -> Comment
switchVisible id comment =
    let
        visible =
            if comment.id == id then
                not comment.visible
            else
                comment.visible

        children =
            case comment.children of
                Responses responses ->
                    Responses <| List.map (\response -> switchVisible id response) responses
    in
    { comment
        | visible = visible
        , children = children
    }



{- RECURSIVE ABILITIES -}


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
        |> hardcoded True
        |> hardcoded False


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


insertDecoder : Decoder Inserted
insertDecoder =
    decode Inserted
        |> required "id" Decode.int
        |> required "parent" (Decode.nullable Decode.int)
        |> required "author" (Decode.nullable Decode.string)
