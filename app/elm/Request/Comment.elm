module Request.Comment exposing (count)

import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams)
import Navigation exposing (Location)


count : Location -> Http.Request String
count location =
    "/count"
        |> HttpBuilder.get
        |> HttpBuilder.withQueryParams [ ( "url", location.pathname ) ]
        |> HttpBuilder.withExpect Http.expectString
        |> HttpBuilder.toRequest
