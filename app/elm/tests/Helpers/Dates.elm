module Helpers.Dates exposing (dateForYear, dateWithinYearRange)

import Fuzz exposing (Fuzzer, int, intRange)
import Time.Date exposing (isLeapYear)
import Time.DateTime exposing (DateTime, addDays, dateTime, zero)


dateForYear : Int -> Fuzzer DateTime
dateForYear year =
    let
        daysUpper =
            if isLeapYear year then
                365

            else
                364
    in
    intRange 0 daysUpper
        |> Fuzz.map (\days -> addDays days (dateTime { zero | year = year }))


dateWithinYearRange : Int -> Int -> Fuzzer DateTime
dateWithinYearRange lower upper =
    intRange lower upper
        |> Fuzz.andThen (\year -> dateForYear year)
