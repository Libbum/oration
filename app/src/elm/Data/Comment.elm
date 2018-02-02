module Data.Comment exposing (Comment, Edited, Inserted, Responses(Responses), count, decoder, delete, disableVote, dislike, editDecoder, encode, getText, insertDecoder, insertNew, like, readOnly, toggleVisible, update)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline exposing (decode, hardcoded, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import Maybe.Extra exposing ((?), isNothing, values)
import Time.DateTime exposing (DateTime)
import Util exposing ((=>))


type alias Comment =
    { text : String
    , author : Maybe String
    , hash : String
    , created : DateTime
    , id : Int
    , votes : Int
    , children : Responses
    , visible : Bool
    , editable : Bool
    , votable : Bool
    }


type Responses
    = Responses (List Comment)


type alias Inserted =
    { id : Int
    , parent : Maybe Int
    , author : Maybe String
    }


type alias Edited =
    { id : Int
    , author : Maybe String
    , hash : String
    , text : String
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
            , votes = 0
            , children = Responses []
            , visible = True
            , editable = True
            , votable = False
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


update : Edited -> List Comment -> List Comment
update edit comments =
    List.map (\comment -> injectUpdates edit comment) comments


injectUpdates : Edited -> Comment -> Comment
injectUpdates edit comment =
    if edit.id == comment.id then
        { comment
            | text = edit.text
            , author = edit.author
            , hash = edit.hash
            , editable = True
        }
    else
        let
            children =
                case comment.children of
                    Responses responses ->
                        Responses <| List.map (\response -> injectUpdates edit response) responses
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


delete : Int -> List Comment -> List Comment
delete id comments =
    List.map (\comment -> filterComment id comment) comments
        |> values


filterComment : Int -> Comment -> Maybe Comment
filterComment id comment =
    let
        --Pure deletes only happen on comments with no children, so only filter if that's the case
        noChildren =
            case comment.children of
                Responses responses ->
                    List.isEmpty responses
    in
    if comment.id == id then
        if noChildren then
            Nothing
        else
            --We must display a masked delete
            let
                children =
                    case comment.children of
                        Responses responses ->
                            Responses <| values <| List.map (\response -> filterComment id response) responses
            in
            Just
                { comment
                    | children = children
                    , author = Nothing
                    , hash = ""
                    , text = ""
                    , votes = 0
                    , votable = False
                }
    else
        let
            children =
                case comment.children of
                    Responses responses ->
                        Responses <| values <| List.map (\response -> filterComment id response) responses
        in
        Just { comment | children = children }


readOnly : Int -> List Comment -> List Comment
readOnly id comments =
    List.map (\comment -> removeEditable id comment) comments


removeEditable : Int -> Comment -> Comment
removeEditable id comment =
    let
        value =
            if comment.id == id then
                False
            else
                comment.editable

        children =
            case comment.children of
                Responses responses ->
                    Responses <| List.map (\response -> removeEditable id response) responses
    in
    { comment
        | editable = value
        , children = children
    }


like : Int -> List Comment -> List Comment
like id comments =
    List.map (\comment -> voteComment id True comment) comments


dislike : Int -> List Comment -> List Comment
dislike id comments =
    List.map (\comment -> voteComment id False comment) comments


voteComment : Int -> Bool -> Comment -> Comment
voteComment id like comment =
    let
        count =
            if comment.id == id then
                case like of
                    True ->
                        comment.votes + 1

                    False ->
                        comment.votes - 1
            else
                comment.votes

        children =
            case comment.children of
                Responses responses ->
                    Responses <| List.map (\response -> voteComment id like response) responses
    in
    { comment
        | votes = count
        , children = children
        , votable = False
    }


disableVote : Int -> List Comment -> List Comment
disableVote id comments =
    List.map (\comment -> removeVotable id comment) comments


removeVotable : Int -> Comment -> Comment
removeVotable id comment =
    let
        value =
            if comment.id == id then
                False
            else
                comment.votable

        children =
            case comment.children of
                Responses responses ->
                    Responses <| List.map (\response -> removeVotable id response) responses
    in
    { comment
        | votable = value
        , children = children
    }



{- INFORMATION GATHERING -}


getText : Int -> List Comment -> String
getText id comments =
    let
        --id is unique, so we will only find one comment that isn't empty,
        --we can take the head of the filtered list
        found =
            foldl (\y ys -> findText id y :: ys) [] comments
                |> List.filter (not << String.isEmpty)
                |> List.head
    in
    case found of
        Just text ->
            text

        Nothing ->
            ""


findText : Int -> Comment -> String
findText id comment =
    if comment.id == id then
        comment.text
    else
        ""



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
        |> required "votes" Decode.int
        |> required "children" decodeResponses
        |> hardcoded True
        |> hardcoded False
        |> hardcoded True


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


editDecoder : Decoder Edited
editDecoder =
    decode Edited
        |> required "id" Decode.int
        |> required "author" (Decode.nullable Decode.string)
        |> required "hash" Decode.string
        |> required "text" Decode.string
