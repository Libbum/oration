module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Identicon exposing (identicon)
import Markdown


main =
    Html.beginnerProgram { model = model, view = view, update = update }



-- MODEL


type alias Model =
    { comment : String
    , name : String
    , email : String
    , url : String
    , preview: Bool
    }


model : Model
model =
    Model "" "" "" "" False



-- UPDATE


type Msg
    = Comment String
    | Name String
    | Email String
    | Url String
    | Preview


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

        Preview ->
            { model | preview = not model.preview }



-- VIEW


view : Model -> Html Msg
view model =
    let
        identity =
            String.concat [ model.name, ", ", model.email, ", ", model.url ]
        markdown =
            markdownContent model.comment model.preview
    in
    div [ id "oration" ]
    [ Html.form [ action "/", method "post", id "oration-form" ]
        [ textarea [ name "comment", placeholder "Write a comment here (min 3 characters).", minlength 3, cols 55, rows 4, onInput Comment ] []
        , br [] []
        , span [ id "oration-identicon", iconStyle ] [ identicon "25px" identity ]
        , input [ type_ "text", name "name", placeholder "Name (optional)", autocomplete True, onInput Name ] []
        , input [ type_ "email", name "email", placeholder "Email (optional)", autocomplete True, onInput Email ] []
        , input [ type_ "url", name "url", placeholder "Website (optional)", onInput Url ] []
        , br [] []
        , input [ type_ "checkbox", name "preview", onClick Preview ] [], text "Preview"
        , input [ type_ "submit", value "Comment" ] []
        , viewValidation model
        ]
    , div [ id "comment-preview" ]
           <| Markdown.toHtml Nothing markdown
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


iconStyle : Attribute Msg
iconStyle =
    style
        [ ( "width", "25px" )
        , ( "height", "25px" )
        , ( "padding", "5px" )
        , ( "margin", "auto" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ]

markdownContent : String -> Bool -> String
markdownContent content preview =
    if preview then
       content

    else
        ""
