module Request.Comment exposing (comments, count, post)

import Data.Comment as Comment exposing (Comment)
import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams)
import Json.Decode as Decode
import Models exposing (Model)
import Navigation exposing (Location)


{-| Request the number of comments for a given post
-}
count : Location -> Http.Request String
count location =
    "/count"
        |> HttpBuilder.get
        |> HttpBuilder.withQueryParams [ ( "url", location.pathname ) ]
        |> HttpBuilder.withExpect Http.expectString
        |> HttpBuilder.toRequest


{-| We want to override the default post behaviour of the form and send this data seemlessly to the backend
-}
post : Model -> Http.Request String
post model =
    let
        --These values will always be sent
        body =
            [ ( "comment", model.comment )
            , ( "title", model.title )
            , ( "path", model.post.pathname )
            ]

        --User details are only sent if they exist
    in
    "/"
        |> HttpBuilder.post
        |> HttpBuilder.withUrlEncodedBody
            (prependMaybe body "name" model.user.name
                ++ prependMaybe body "email" model.user.email
                ++ prependMaybe body "url" model.user.url
            )
        |> HttpBuilder.withExpect Http.expectString
        |> HttpBuilder.toRequest


{-| Request the comments for the current url
-}
comments : Location -> Http.Request (List Comment)
comments location =
    let
        expect =
            Decode.list Comment.decoder
                |> Decode.field "comments"
                |> Http.expectJson
    in
    "/comments"
        |> HttpBuilder.get
        |> HttpBuilder.withQueryParams [ ( "url", location.pathname ) ]
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
