module Tests exposing (..)

import Data.Comment exposing (Comment, Responses(Responses))
import Data.User exposing (User)
import Expect exposing (..)
import Fuzz exposing (Fuzzer, bool, int, list, maybe, string, tuple)
import Helpers.Dates exposing (dateWithinYearRange)
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (..)
import Time.DateTime exposing (DateTime)
import Util exposing (..)


user : Fuzzer User
user =
    Fuzz.map5 User
        (maybe string)
        (maybe string)
        (maybe string)
        (maybe string)
        bool



{-
   commentEncode : Fuzzer Comment
   commentEncode =
       Fuzz.map3 Comment
           string
           (maybe string)
           string



      commentDecode : Fuzzer Comment
      commentDecode =
          Fuzz.map5 Comment
              string
              (maybe string)
              string
              (maybe (dateNear 2017))
              int
              |> Fuzz.andMap (list (Fuzz.constant []))

-}


dateNear : Int -> Fuzzer DateTime
dateNear y =
    dateWithinYearRange (y - 2) (y + 2)


all : Test
all =
    describe "Oration Front-end Test Suite"
        [ describe "Unit tests"
            [ test "String to Maybe String - Empty String" <|
                \() ->
                    Expect.equal (stringToMaybe "") Nothing
            , test "String to Maybe String - String" <|
                \() ->
                    Expect.equal (stringToMaybe "Something") (Just "Something")
            ]
        , describe "Fuzz tests"
            [ fuzz2 int (list string) "Pair generates tuples" <|
                \first second ->
                    pair first second
                        |> Expect.equal ( first, second )
            ]
        , describe "Data.User"
            [ fuzz user "Serialization round trip" <|
                \thisUser ->
                    thisUser
                        |> Data.User.encode
                        |> Decode.decodeValue Data.User.decoder
                        |> Expect.equal (Ok thisUser)
            ]

        {- , describe "Data.Comment"
           [ fuzz commentDecode "Serialization Decode" <|
               \thisComment ->
                   thisComment
                       |> Decode.decodeValue Data.Comment.decoder
                       |> Expect.equal (Ok thisComment)
                       ]
        -}
        ]
