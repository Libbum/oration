module Update exposing (currentDate, subscriptions, update)

import Data.Comment as Comment
import Http
import Maybe.Extra exposing ((?))
import Models exposing (Model)
import Msg exposing (Msg(..))
import Ports
import Request.Comment
import Task
import Time exposing (minute)
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
            { model | now = date } ! []

        Math newMath ->
            { model | math = newMath } ! []

        GetMath ->
            model ! [ Ports.renderMath model.comment ]

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
        , Ports.parsedMath Math
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
    Time.now |> Task.map timeToDateTime


timeToDateTime : Time.Time -> DateTime
timeToDateTime =
    Time.DateTime.fromTimestamp
