module Update exposing (..)

import Models exposing (Model)
--import Storage exposing (saveUserState,userStateLoaded,injectChanges)
import Msg exposing (Msg(..))

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Comment comment ->
            ({ model | comment = comment }, Cmd.none)

        Name name ->
            ({ model | name = name }, Cmd.none)

        Email email ->
            ({ model | email = email }, Cmd.none)

        Url url ->
            ({ model | url = url }, Cmd.none)

        Preview ->
            ({ model | preview = not model.preview }, Cmd.none)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
    [
    ]
