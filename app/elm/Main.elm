module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


main =
    Html.beginnerProgram { model = model, view = view, update = update }



-- MODEL


type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    }


model : Model
model =
    Model "" "" "" ""



-- UPDATE


type Msg
    = Comment String
    | Name String
    | Email String
    | Url String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Comment comment ->
            { model | comment = comment }

        Name name ->
            { model | name = name }

        Email email ->
            { model | email = email }

        Url url ->
            { model | url = url }



-- VIEW


view : Model -> Html Msg
view model =
    Html.form [ action "/", method "post" ]
        [ textarea [ name "comment", placeholder "Write a comment here (min 3 characters).", minlength 3, cols 55, rows 4, onInput Comment ] []
        , br [] []
        , input [ type_ "text", name "name", placeholder "Name (optional)", autocomplete True, onInput Name ] []
        , input [ type_ "email", name "email", placeholder "Email (optional)", autocomplete True, onInput Email ] []
        , input [ type_ "url", name "url", placeholder "Website (optional)", onInput Url ] []
        , br [] []
        , input [ type_ "submit", value "Comment" ] []
        , viewValidation model
        ]


viewValidation : Model -> Html msg
viewValidation model =
    let
        ( color, message ) =
            if String.length model.comment > 3 then
                ( "green", "OK" )
            else
                ( "red", "Comment it too short." )
    in
    div [ style [ ( "color", color ) ] ] [ text message ]
