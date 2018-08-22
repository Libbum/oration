module Update exposing (currentDate, subscriptions, update)

import Data.Comment as Comment
import Data.User exposing (getIdentity)
import Http
import Maybe.Extra exposing ((?))
import Models exposing (Model, Status(..))
import Msg exposing (Msg(..))
import Ports
import Request.Comment
import Task
import Time exposing (minute)
import Time.DateTime exposing (DateTime)
import Util exposing (delay)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateComment comment ->
            ( { model | comment = comment }
            , Cmd.none
            )

        UpdateName name ->
            let
                user =
                    model.user
            in
            ( { model | user = { user | name = name } }
            , Cmd.none
            )

        UpdateEmail email ->
            let
                user =
                    model.user
            in
            ( { model | user = { user | email = email } }
            , Cmd.none
            )

        UpdateUrl url ->
            let
                user =
                    model.user
            in
            ( { model | user = { user | url = url } }
            , Cmd.none
            )

        UpdatePreview ->
            let
                user =
                    model.user
            in
            ( { model | user = { user | preview = not model.user.preview } }
            , Cmd.none
            )

        SetPreview strPreview ->
            let
                user =
                    model.user

                preview_ =
                    dumbDecode strPreview
            in
            ( { model | user = { user | preview = preview_ } }
            , Cmd.none
            )

        StoreUser ->
            ( model
            , Cmd.batch
                [ Ports.setName model.user.name
                , Ports.setEmail model.user.email
                , Ports.setUrl model.user.url
                , Ports.setPreview (Just <| toString model.user.preview)
                ]
            )

        Count (Ok strCount) ->
            let
                intCount =
                    case String.toInt strCount of
                        Ok val ->
                            val

                        Err _ ->
                            0
            in
            ( { model | count = intCount }
            , Cmd.none
            )

        Count (Err error) ->
            ( { model | debug = toString error }
            , Cmd.none
            )

        Post location ->
            ( { model | post = location }
            , Cmd.none
            )

        Title value ->
            ( { model | title = value }
            , Cmd.none
            )

        PostComment ->
            ( model
            , let
                postReq =
                    Request.Comment.post model
                        |> Http.toTask
              in
              Task.attempt PostConfirm postReq
            )

        PostConfirm (Ok result) ->
            let
                user =
                    model.user

                author =
                    getIdentity user

                comments =
                    Comment.insertNew result ( model.comment, author, model.now, model.comments )
            in
            ( { model
                | comment = ""
                , parent = Nothing
                , count = model.count + 1
                , debug = toString result
                , comments = comments
                , status = Commenting
                , user = { user | identity = author }
              }
            , timeoutEdits model.editTimeout result.id
            )

        PostConfirm (Err error) ->
            ( { model | debug = toString error }
            , Cmd.none
            )

        Hashes (Ok result) ->
            let
                user =
                    model.user
            in
            ( { model
                | user =
                    { user
                        | iphash = result.userIp
                        , identity = getIdentity user
                    }
                , blogAuthor = result.blogAuthor ? ""
                , editTimeout = result.editTimeout
              }
            , Cmd.none
            )

        Hashes (Err error) ->
            ( { model | debug = toString error }
            , Cmd.none
            )

        Comments (Ok result) ->
            let
                count =
                    Comment.count result
            in
            ( { model
                | comments = result
                , count = count
              }
            , Cmd.none
            )

        Comments (Err error) ->
            ( { model | debug = toString error }
            , Cmd.none
            )

        GetDate _ ->
            ( model
            , Task.perform NewDate currentDate
            )

        NewDate date ->
            ( { model | now = date }
            , Cmd.none
            )

        CommentReply id ->
            let
                value =
                    if model.parent == Just id then
                        Nothing

                    else
                        Just id

                status =
                    if model.parent == Just id then
                        Commenting

                    else
                        Replying
            in
            ( { model
                | parent = value
                , status = status
              }
            , Cmd.none
            )

        CommentEdit id ->
            let
                value =
                    if model.parent == Just id then
                        Nothing

                    else
                        Just id

                status =
                    if model.parent == Just id then
                        Commenting

                    else
                        Editing

                comment =
                    if model.parent == Just id then
                        ""

                    else
                        Comment.getText id model.comments
            in
            ( { model
                | parent = value
                , comment = comment
                , status = status
              }
            , timeoutEdits model.editTimeout id
            )

        SendEdit id ->
            ( model
            , let
                postReq =
                    Request.Comment.edit id model
                        |> Http.toTask
              in
              Task.attempt EditConfirm postReq
            )

        EditConfirm (Ok result) ->
            let
                user =
                    model.user

                comments =
                    Comment.update result model.comments
            in
            ( { model
                | debug = toString result
                , status = Commenting
                , comments = comments
                , comment = ""
                , parent = Nothing
                , user = { user | identity = getIdentity user }
              }
            , timeoutEdits model.editTimeout result.id
            )

        EditConfirm (Err error) ->
            ( { model | debug = toString error }
            , Cmd.none
            )

        CommentDelete id ->
            ( model
            , let
                postReq =
                    Request.Comment.delete id model.user.identity
                        |> Http.toTask
              in
              Task.attempt DeleteConfirm postReq
            )

        DeleteConfirm (Ok result) ->
            let
                comments =
                    Comment.delete result model.comments
            in
            ( { model
                | debug = toString result
                , comments = comments
              }
            , Cmd.none
            )

        DeleteConfirm (Err error) ->
            ( { model | debug = toString error }
            , Cmd.none
            )

        CommentLike id ->
            ( model
            , let
                postReq =
                    Request.Comment.like id
                        |> Http.toTask
              in
              Task.attempt LikeConfirm postReq
            )

        LikeConfirm (Ok result) ->
            let
                comments =
                    Comment.like result model.comments
            in
            ( { model
                | debug = toString result
                , comments = comments
              }
            , Cmd.none
            )

        LikeConfirm (Err error) ->
            let
                comments =
                    case error of
                        Http.BadStatus status ->
                            Comment.disableVote (Result.withDefault -1 (String.toInt status.body)) model.comments

                        _ ->
                            model.comments

                print =
                    case error of
                        Http.BadStatus status ->
                            toString status.status ++ ", " ++ status.body

                        _ ->
                            toString error
            in
            ( { model
                | debug = print
                , comments = comments
              }
            , Cmd.none
            )

        CommentDislike id ->
            ( model
            , let
                postReq =
                    Request.Comment.dislike id
                        |> Http.toTask
              in
              Task.attempt DislikeConfirm postReq
            )

        DislikeConfirm (Ok result) ->
            let
                comments =
                    Comment.dislike result model.comments
            in
            ( { model
                | debug = toString result
                , comments = comments
              }
            , Cmd.none
            )

        DislikeConfirm (Err error) ->
            let
                comments =
                    case error of
                        Http.BadStatus status ->
                            Comment.disableVote (Result.withDefault -1 (String.toInt status.body)) model.comments

                        _ ->
                            model.comments

                print =
                    case error of
                        Http.BadStatus status ->
                            toString status.status ++ ", " ++ status.body

                        _ ->
                            toString error
            in
            ( { model
                | debug = print
                , comments = comments
              }
            , Cmd.none
            )

        HardenEdit id ->
            let
                comments =
                    case model.status of
                        Editing ->
                            model.comments

                        _ ->
                            Comment.readOnly id model.comments
            in
            ( { model | comments = comments }
            , Cmd.none
            )

        ToggleCommentVisibility id ->
            let
                comments =
                    Comment.toggleVisible id model.comments
            in
            ( { model | comments = comments }
            , Cmd.none
            )


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
dumbDecode : Maybe String -> Bool
dumbDecode val =
    case val of
        Just decoded ->
            if decoded == "True" then
                True

            else
                False

        Nothing ->
            False


currentDate : Task.Task x DateTime
currentDate =
    Time.now |> Task.map timeToDateTime


timeToDateTime : Time.Time -> DateTime
timeToDateTime =
    Time.DateTime.fromTimestamp


timeoutEdits : Float -> Int -> Cmd Msg
timeoutEdits timeout id =
    delay (Time.second * timeout) <| HardenEdit id
