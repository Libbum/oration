module Update exposing (subscriptions, update)

import Date
import Http
import LocalStorage
import Maybe.Extra exposing ((?))
import Models exposing (Model)
import Msg exposing (Msg(..))
import Ports exposing (title)
import Request.Comment
import Task
import Time exposing (Time, minute)
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

        OnKeys result ->
            case result of
                Ok keys ->
                    update (SetUser keys) model

                Err _ ->
                    --We don't care if the pull fails, we just set keep defaults
                    model ! []

        SetUser keys ->
            model ! [ requestValues keys ]

        OnGet key result ->
            case result of
                Ok maybeValue ->
                    update (SetUserValue key maybeValue) model

                Err _ ->
                    model ! []

        OnVoidOp result ->
            case result of
                Ok _ ->
                    update Refresh model

                Err _ ->
                    model ! []

        Refresh ->
            model ! [ Task.attempt OnKeys LocalStorage.keys ]

        AfterSetValue key val result ->
            case result of
                Ok _ ->
                    update (SetUserValue key (Just val)) model

                Err _ ->
                    model ! []

        SetUserValue key valueMaybe ->
            case valueMaybe of
                Just value ->
                    let
                        user =
                            model.user

                        --TODO: Would be nice if this was cleaner, but I'm not sure how atm.
                        name_ =
                            if key == "name" then
                                stringToMaybe value
                            else
                                model.user.name

                        email_ =
                            if key == "email" then
                                stringToMaybe value
                            else
                                model.user.email

                        url_ =
                            if key == "url" then
                                stringToMaybe value
                            else
                                model.user.url

                        preview_ =
                            if key == "preview" then
                                dumbDecode value
                            else
                                model.user.preview
                    in
                    { model
                        | user =
                            { user
                                | name = name_
                                , email = email_
                                , url = url_
                                , preview = preview_
                            }
                    }
                        ! []

                Nothing ->
                    model ! []

        StoreUser ->
            model ! [ storeUser model ]

        Title value ->
            { model | title = value } ! []

        PostComment ->
            { model
                | comment = ""
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

        Hash (Ok result) ->
            let
                user =
                    model.user
            in
            { model | user = { user | iphash = Just result } } ! []

        Hash (Err _) ->
            model ! []

        Comments (Ok result) ->
            { model | comments = result } ! []

        Comments (Err _) ->
            model ! []

        GetDate _ ->
            model ! [ Task.perform NewDate Date.now ]

        NewDate date ->
            { model | now = Just date } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ title Title
        , Time.every minute GetDate
        ]


{-| localStorage values are always strings. We store the preview bool via toString, so this will be good enough as a decoder.
-}
dumbDecode : Msg.Value -> Bool
dumbDecode val =
    if val == "True" then
        True
    else
        False


{-| Request the users' information from localstorage.
-}
requestValues : List LocalStorage.Key -> Cmd Msg
requestValues keys =
    let
        requestKey key =
            Task.attempt (OnGet key) (LocalStorage.get key)
    in
    Cmd.batch <| List.map requestKey keys


{-| Store user information to localstorage
-}
storeUser : Model -> Cmd Msg
storeUser model =
    let
        storeData key value =
            Task.attempt (AfterSetValue key value) (LocalStorage.set key value)

        preview_ =
            toString model.user.preview

        keys =
            [ "name", "email", "url", "preview" ]

        values =
            [ model.user.name ? "", model.user.email ? "", model.user.url ? "", preview_ ]
    in
    Cmd.batch <| List.map2 storeData keys values
