module Request.User exposing (hash)

import Http
import HttpBuilder exposing (RequestBuilder, withQueryParams)


{-| Request a hash of the users IP
-}
hash : Http.Request String
hash =
    "/hash"
        |> HttpBuilder.get
        |> HttpBuilder.withExpect Http.expectString
        |> HttpBuilder.toRequest
