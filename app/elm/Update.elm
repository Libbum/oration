module Update exposing (..)

import Http
import LocalStorage
import Models exposing (Model)
import Msg exposing (Msg(..))
import Ports exposing (title)
import Task


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Comment comment ->
            ( { model | comment = comment }, Cmd.none )

        Name name ->
            ( { model | name = name }, Cmd.none )

        Email email ->
            ( { model | email = email }, Cmd.none )

        Url url ->
            ( { model | url = url }, Cmd.none )

        Preview ->
            ( { model | preview = not model.preview }, Cmd.none )

        Count (Ok strCount) ->
            let
                intCount =
                    case String.toInt strCount of
                        Ok val ->
                            val

                        Err _ ->
                            0
            in
            ( { model | count = intCount }, Cmd.none )

        Count (Err _) ->
            ( model, Cmd.none )

        Post location ->
            ( { model | post = location }, Cmd.none )

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

                Err err ->
                    model ! []

        Refresh ->
            model ! [ Task.attempt OnKeys LocalStorage.keys ]

        AfterSetValue key val result ->
            case result of
                Ok _ ->
                    update (SetUserValue key (Just val)) model

                Err err ->
                    model ! []

        SetUserValue key valueMaybe ->
            case valueMaybe of
                Just value ->
                    let
                        --TODO: Would be nice if this was cleaner, but I'm not sure how atm.
                        name_ =
                            if key == "name" then
                                value
                            else
                                model.name

                        email_ =
                            if key == "email" then
                                value
                            else
                                model.email

                        url_ =
                            if key == "url" then
                                value
                            else
                                model.url

                        preview_ =
                            if key == "preview" then
                                dumbDecode value
                            else
                                model.preview
                    in
                    { model
                        | name = name_
                        , email = email_
                        , url = url_
                        , preview = preview_
                    }
                        ! []

                Nothing ->
                    model ! []

        StoreUser ->
            model ! [ storeUser model ]

        Title value ->
            { model | title = value } ! []

        PostComment ->
            { model | comment = "" } ! [ postComment model ]

        --TODO: Proper responses are needed
        ReceiveHttp result ->
            let
                response =
                    case result of
                        Ok val ->
                            val

                        Err err ->
                            "Error!"
            in
            { model | httpResponse = response } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    title Title


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
            toString model.preview

        keys =
            [ "name", "email", "url", "preview" ]

        values =
            [ model.name, model.email, model.url, preview_ ]
    in
    Cmd.batch <| List.map2 storeData keys values


{-| We want to override the default post behaviour and send this data seemlessly to the backend
-}
postComment : Model -> Cmd Msg
postComment model =
    let
        body =
            String.concat [ "comment=", model.comment
                          , "&name=", model.name
                          , "&email=", model.email
                          , "&url=", model.url
                          , "&title=", model.title
                          , "&path=", model.post.pathname
                          ]
    in
    Http.send ReceiveHttp <|
        Http.request
            { method = "POST"
            , headers = []
            , url = "/"
            , body =
                Http.stringBody "application/x-www-form-urlencoded" body
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }
