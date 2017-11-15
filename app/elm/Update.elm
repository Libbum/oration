module Update exposing (currentDate, subscriptions, update)

import Data.Comment as Comment
import Date as CoreDate
import Http
import Maybe.Extra exposing ((?))
import Models exposing (Model)
import Msg exposing (Msg(..))
import Ports
import Request.Comment
import Task
import Time exposing (Time, minute)
import Time.DateTime exposing (DateTime)
import Util exposing (stringToMaybe)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateComment comment ->
            { model | comment = comment } ! []

        UpdateName name ->
            let
                user =
                    model.user
            in
            { model | user = { user | name = stringToMaybe name } } ! []

        UpdateEmail email ->
            let
                user =
                    model.user
            in
            { model | user = { user | email = stringToMaybe email } } ! []

        UpdateUrl url ->
            let
                user =
                    model.user
            in
            { model | user = { user | url = stringToMaybe url } } ! []

        UpdatePreview ->
            let
                user =
                    model.user
            in
            { model | user = { user | preview = not model.user.preview } } ! []

        SetPreview strPreview ->
            let
                user =
                    model.user

                preview_ =
                    dumbDecode strPreview
            in
            { model | user = { user | preview = preview_ } } ! []

        StoreUser ->
            model
                ! [ Cmd.batch
                        [ Ports.setName (model.user.name ? "")
                        , Ports.setEmail (model.user.email ? "")
                        , Ports.setUrl (model.user.url ? "")
                        , Ports.setPreview (toString model.user.preview)
                        ]
                  ]

        Count (Ok strCount) ->
            let
                intCount =
                    case String.toInt strCount of
                        Ok val ->
                            val

                        Err _ ->
                            0
            in
            { model | count = intCount } ! []

        Count (Err _) ->
            model ! []

        Post location ->
            { model | post = location } ! []

        Title value ->
            { model | title = value } ! []

        PostComment ->
            { model
                | comment = ""
                , parent = Nothing
                , count = model.count + 1
            }
                ! [ let
                        postReq =
                            Request.Comment.post model
                                |> Http.toTask
                    in
                    Task.attempt ReceiveHttp postReq
                  ]

        --TODO: Proper responses are needed
        ReceiveHttp result ->
            let
                response =
                    case result of
                        Ok val ->
                            val

                        Err _ ->
                            "Error!"
            in
            { model | httpResponse = response } ! []

        Hashes (Ok result) ->
            let
                user =
                    model.user
            in
            { model
                | user = { user | iphash = result.userIp }
                , blogAuthor = result.blogAuthor ? ""
            }
                ! []

        Hashes (Err _) ->
            model ! []

        Comments (Ok result) ->
            let
                count =
                    Comment.count result
            in
            { model
                | comments = result
                , count = count
            }
                ! []

        Comments (Err _) ->
            model ! []

        GetDate _ ->
            model ! [ Task.perform NewDate currentDate ]

        NewDate date ->
            { model | now = Just date } ! []

        CommentReply id ->
            let
                current =
                    model.parent

                value =
                    if current == Just id then
                        Nothing
                    else
                        Just id
            in
            { model | parent = value } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.title Title
        , Ports.name UpdateName
        , Ports.email UpdateEmail
        , Ports.url UpdateUrl
        , Ports.preview SetPreview
        , Time.every minute GetDate
        ]


{-| localStorage values are always strings. We store the preview bool via toString, so this will be good enough as a decoder.
-}
dumbDecode : String -> Bool
dumbDecode val =
    if val == "True" then
        True
    else
        False


currentDate : Task.Task x DateTime
currentDate =
    CoreDate.now |> Task.map coreDateToDate


coreDateToDate : CoreDate.Date -> DateTime
coreDateToDate core =
    let
        convert =
            ( CoreDate.year core, coreMonthToInt <| CoreDate.month core, CoreDate.day core, CoreDate.hour core, CoreDate.minute core, CoreDate.second core, CoreDate.millisecond core )
    in
    Time.DateTime.fromTuple convert


coreMonthToInt : CoreDate.Month -> Int
coreMonthToInt month =
    case month of
        CoreDate.Jan ->
            1

        CoreDate.Feb ->
            2

        CoreDate.Mar ->
            3

        CoreDate.Apr ->
            4

        CoreDate.May ->
            5

        CoreDate.Jun ->
            6

        CoreDate.Jul ->
            7

        CoreDate.Aug ->
            8

        CoreDate.Sep ->
            9

        CoreDate.Oct ->
            10

        CoreDate.Nov ->
            11

        CoreDate.Dec ->
            12
