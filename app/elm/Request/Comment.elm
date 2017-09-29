module Request.Comment exposing (count, post)

import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams)
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


prependMaybe : List ( a, a ) -> a -> Maybe a -> List ( a, a )
prependMaybe list id maybe =
    case maybe of
        Just value ->
            ( id, value ) :: list

        Nothing ->
            list
