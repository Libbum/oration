module Request.Comment exposing (comments, count, delete, dislike, edit, like, post)

import Data.Comment as Comment exposing (Comment, Edited, Inserted)
import Data.User exposing (Identity)
import Http
import HttpBuilder
import Json.Decode as Decode
import Models exposing (Model)


{-| Request the number of comments for a given post
-}
count : String -> Http.Request String
count pathname =
    "/oration/count"
        |> HttpBuilder.get
        |> HttpBuilder.withQueryParams [ ( "url", pathname ) ]
        |> HttpBuilder.withExpect Http.expectString
        |> HttpBuilder.toRequest


{-| We want to override the default post behaviour of the form and send this data seemlessly to the backend
-}
post : Model -> Http.Request Inserted
post model =
    let
        --These values will always be sent
        body =
            [ ( "comment", model.comment )
            , ( "title", model.title )
            , ( "path", model.pathname )
            ]

        --User details are only sent if they exist
        expect =
            Comment.insertDecoder
                |> Http.expectJson
    in
    "/oration"
        |> HttpBuilder.post
        |> HttpBuilder.withUrlEncodedBody
            (prependMaybe body "parent" (Maybe.map toString model.parent)
                ++ prependMaybe body "name" model.user.name
                ++ prependMaybe body "email" model.user.email
                ++ prependMaybe body "url" model.user.url
            )
        |> HttpBuilder.withExpect expect
        |> HttpBuilder.toRequest



{- Request to edit a given comment -}


edit : Int -> Model -> Http.Request Edited
edit id model =
    let
        --Only the comment itself and possibly author details can be edited
        --We need to send new author info, but the old hash to verify the edit
        body =
            [ ( "comment", model.comment ) ]

        --We post here since we are only sending a few pieces of information
        --See https://stormpath.com/blog/put-or-post
        expect =
            Comment.editDecoder
                |> Http.expectJson
    in
    "/oration/edit"
        |> HttpBuilder.post
        |> HttpBuilder.withHeader "x-auth-hash" model.user.identity
        |> HttpBuilder.withQueryParams [ ( "id", toString id ) ]
        |> HttpBuilder.withUrlEncodedBody
            (prependMaybe body "name" model.user.name
                ++ prependMaybe body "email" model.user.email
                ++ prependMaybe body "url" model.user.url
            )
        |> HttpBuilder.withExpect expect
        |> HttpBuilder.toRequest



{- Request to like a given comment -}


like : Int -> Http.Request Int
like id =
    "/oration/like"
        |> HttpBuilder.post
        |> HttpBuilder.withQueryParams [ ( "id", toString id ) ]
        |> HttpBuilder.withExpect (Http.expectStringResponse (\response -> Ok (Result.withDefault -1 (String.toInt response.body))))
        |> HttpBuilder.toRequest



{- Request to dislike a given comment -}


dislike : Int -> Http.Request Int
dislike id =
    "/oration/dislike"
        |> HttpBuilder.post
        |> HttpBuilder.withQueryParams [ ( "id", toString id ) ]
        |> HttpBuilder.withExpect (Http.expectStringResponse (\response -> Ok (Result.withDefault -1 (String.toInt response.body))))
        |> HttpBuilder.toRequest



{- Request to delete a given comment -}


delete : Int -> Identity -> Http.Request Int
delete id identity =
    "/oration/delete"
        |> HttpBuilder.delete
        |> HttpBuilder.withHeader "x-auth-hash" identity
        |> HttpBuilder.withQueryParams [ ( "id", toString id ) ]
        |> HttpBuilder.withExpect (Http.expectStringResponse (\response -> Ok (Result.withDefault -1 (String.toInt response.body))))
        |> HttpBuilder.toRequest


{-| Request the comments for the current url
-}
comments : String -> Http.Request (List Comment)
comments pathname =
    let
        expect =
            Decode.list Comment.decoder
                |> Decode.field "comments"
                |> Http.expectJson
    in
    "/oration/comments"
        |> HttpBuilder.get
        |> HttpBuilder.withQueryParams [ ( "url", pathname ) ]
        |> HttpBuilder.withExpect expect
        |> HttpBuilder.toRequest


{-| Adds a pair to the list so long as there is data in the second
-}
prependMaybe : List ( a, a ) -> a -> Maybe a -> List ( a, a )
prependMaybe list id maybe =
    case maybe of
        Just value ->
            ( id, value ) :: list

        Nothing ->
            list
