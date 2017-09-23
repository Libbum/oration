module Update exposing (..)

import Dict exposing (Dict)
import LocalStorage
import Models exposing (Model)
import Msg exposing (Msg(..))
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
                        Err _ ->
                            0

                        Ok val ->
                            val
            in
            ( { model | count = intCount }, Cmd.none )

        Count (Err _) ->
            ( model, Cmd.none )

        Post location ->
            ( { model | post = location }, Cmd.none )

        OnKeys result ->
            case result of
                Ok keys ->
                    update (SetLocalKeys keys) model

                Err err ->
                    onError err model

        SetLocalKeys keys ->
            { model | keys = keys } ! [ requestValues keys ]

        OnGet key result ->
            case result of
                Ok maybeValue ->
                    update (SetLocalValue key maybeValue) model

                Err err ->
                    onError err model

        OnVoidOp result ->
            case result of
                Ok _ ->
                    update Refresh model

                Err err ->
                    onError err model

        Refresh ->
            model ! [ Task.attempt OnKeys LocalStorage.keys ]

        AfterSetValue key val result ->
            case result of
                Ok _ ->
                    update (SetLocalValue key (Just val)) model

                Err err ->
                    onError err model

        SetLocalValue key valueMaybe ->
            case valueMaybe of
                Just value ->
                    let
                        values_ =
                            Dict.insert key value model.values
                    in
                    { model | values = values_ } ! []

                Nothing ->
                    model ! []

        StoreUser ->
            model
                ! [ Cmd.batch
                        [ --TODO: Clean this up. I'm sure it's possible to map over these keys somehow
                          Task.attempt (AfterSetValue "name" model.name) (LocalStorage.set "name" model.name)
                        , Task.attempt (AfterSetValue "email" model.email) (LocalStorage.set "email" model.email)
                        , Task.attempt (AfterSetValue "url" model.url) (LocalStorage.set "url" model.url)
                        , Task.attempt (AfterSetValue "preview" (toString model.preview)) (LocalStorage.set "preview" (toString model.preview))
                        ]
                  ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []


onError : LocalStorage.Error -> Model -> ( Model, Cmd Msg )
onError err model =
    { model | errors = err :: model.errors } ! []


{-| Create a command to request the values from localstorage of the given keys.
-}
requestValues : List LocalStorage.Key -> Cmd Msg
requestValues keys =
    let
        requestKey key =
            Task.attempt (OnGet key) (LocalStorage.get key)
    in
    Cmd.batch <| List.map requestKey keys
