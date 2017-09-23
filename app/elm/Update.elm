module Update exposing (..)

--import Storage exposing (saveUserState,userStateLoaded,injectChanges)

import Models exposing (Model)
import Msg exposing (Msg(..))


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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []

