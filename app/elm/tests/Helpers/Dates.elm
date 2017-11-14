module Helpers.Dates exposing (..)

import Fuzz exposing (Fuzzer, int, intRange)
import Time.Date exposing (Date, addDays, date, isLeapYear)


dateForYear : Int -> Fuzzer Date
dateForYear year =
    let
        daysUpper =
            if isLeapYear year then
                365
            else
                364
    in
    intRange 0 daysUpper
        |> Fuzz.map (\days -> addDays days (date year 1 1))


dateWithinYearRange : Int -> Int -> Fuzzer Date
dateWithinYearRange lower upper =
    intRange lower upper
        |> Fuzz.andThen (\year -> dateForYear year)
