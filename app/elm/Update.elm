module Update exposing (currentDate, subscriptions, update)

import Data.Comment as Comment
import Data.User exposing (getIdentity)
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

        Count (Err error) ->
            { model | debug = toString error } ! []

        Post location ->
            { model | post = location } ! []

        Title value ->
            { model | title = value } ! []

        PostComment ->
            model
                ! [ let
                        postReq =
                            Request.Comment.post model
                                |> Http.toTask
                    in
                    Task.attempt PostConfirm postReq
                  ]

        PostConfirm (Ok result) ->
            let
                author =
                    getIdentity model.user

                comments =
                    Comment.insertNew result ( model.comment, author, model.now, model.comments )
            in
            { model
                | comment = ""
                , parent = Nothing
                , count = model.count + 1
                , debug = toString result
                , comments = comments
            }
                ! []

        --! [ Ports.scrollTo ("comment-" ++ toString result.id) ]
        --! [ Dom.focus "comment-30" |> Task.attempt (always NoOp) ]
        --! [ toTop ("comment-" ++ toString result.id) |> Task.attempt ScrollResult ]
        PostConfirm (Err error) ->
            { model | debug = toString error } ! []

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

        Hashes (Err error) ->
            { model | debug = toString error } ! []

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

        Comments (Err error) ->
            { model | debug = toString error } ! []

        GetDate _ ->
            model ! [ Task.perform NewDate currentDate ]

        NewDate date ->
            { model | now = date } ! []

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

        CommentEdit id ->
            model
                ! [ let
                        postReq =
                            Request.Comment.edit id model
                                |> Http.toTask
                    in
                    Task.attempt EditConfirm postReq
                  ]

        EditConfirm (Ok result) ->
            { model | debug = toString result } ! []

        EditConfirm (Err error) ->
            { model | debug = toString error } ! []

        CommentDelete id ->
            model
                ! [ let
                        postReq =
                            Request.Comment.delete id
                                |> Http.toTask
                    in
                    Task.attempt DeleteConfirm postReq
                  ]

        DeleteConfirm (Ok result) ->
            let
                comments =
                    Comment.delete result model.comments
            in
            { model
                | debug = toString result
                , comments = comments
            }
                ! []

        DeleteConfirm (Err error) ->
            { model | debug = toString error } ! []

        ToggleCommentVisibility id ->
            let
                comments =
                    Comment.toggleVisible id model.comments
            in
            { model | comments = comments } ! []


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
    Time.now |> Task.map timeToDateTime


timeToDateTime : Time.Time -> DateTime
timeToDateTime =
    Time.DateTime.fromTimestamp
