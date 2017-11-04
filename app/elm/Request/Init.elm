module Request.Init exposing (hashes)

import Data.Init as Init exposing (Init)
import Http
import HttpBuilder


{-| Request a hash of the users IP and the hash of the blog author (if set)
-}
hashes : Http.Request Init
hashes =
    let
        expect =
            Init.decoder
                |> Http.expectJson
    in
    "/init"
        |> HttpBuilder.get
        |> HttpBuilder.withExpect expect
        |> HttpBuilder.toRequest
