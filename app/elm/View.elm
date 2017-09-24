module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Identicon exposing (identicon)
import LocalStorage
import Markdown
import Models exposing (Model)
import Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
    let
        identity =
            String.concat [ model.name, ", ", model.email, ", ", model.url ]

        markdown =
            markdownContent model.comment model.preview

        count =
            toString model.count ++ " comments"
    in
    div [ id "oration" ]
        [ h2 [] [ text count ]
        , h2 [] [ text model.post.pathname ]
        , h2 [] [ text model.title ]
        , Html.form [ action "/", method "post", id "oration-form" ]
            [ textarea [ name "comment", placeholder "Write a comment here (min 3 characters).", minlength 3, cols 55, rows 4, onInput Comment ] []
            , div [ id "oration-control" ]
                [ span [ id "oration-identicon" ] [ identicon "25px" identity ]
                , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue model.name, autocomplete True, onInput Name ] []
                , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue model.email, autocomplete True, onInput Email ] []
                , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue model.url, onInput Url ] []
                , input [ type_ "checkbox", id "oration-preview-check", checked model.preview, onClick Preview ] []
                , label [ for "oration-preview-check" ] [ text "Preview" ]
                , input [ type_ "submit", class "oration-submit", value "Comment", onClick StoreUser ] []
                ]
            , viewValidation model
            ]
        , div [ id "comment-preview" ] <|
            Markdown.toHtml Nothing markdown
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
    div [ class color ] [ text message ]


markdownContent : String -> Bool -> String
markdownContent content preview =
    if preview then
        content
    else
        ""
