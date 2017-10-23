module Tests exposing (..)

import Expect exposing (..)
import Fuzz exposing (Fuzzer, int, list, maybe, string, tuple)
import Test exposing (..)
import Util exposing (..)


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
        ]
