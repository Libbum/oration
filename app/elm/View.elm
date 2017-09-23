module View exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Identicon exposing (identicon)
import LocalStorage
import Markdown
import Models exposing (Model)
import Msg exposing (Msg(..))
import Task


view : Model -> Html Msg
view model =
    let
        storedName =
            getValue "name" model

        storedEmail =
            getValue "email" model

        storedURL =
            getValue "url" model

        storedPreview =
            getValue "preview" model

        identity =
            --TODO: Identity does not update to the correct value if using stored info. This is because we don't set the model values yet.
            String.concat [ model.name, ", ", model.email, ", ", model.url ]

        markdown =
            markdownContent model.comment model.preview

        count =
            toString model.count ++ " comments"
    in
    div [ id "oration" ]
        [ h2 [] [ text count ]
        , h2 [] [ text model.post.pathname ]
        , Html.form [ action "/", method "post", id "oration-form" ]
            [ textarea [ name "comment", placeholder "Write a comment here (min 3 characters).", minlength 3, cols 55, rows 4, onInput Comment ] []
            , div [ id "oration-control" ]
                [ span [ id "oration-identicon" ] [ identicon "25px" identity ]
                , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue storedName, autocomplete True, onInput Name ] []
                , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue storedEmail, autocomplete True, onInput Email ] []
                , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue storedURL, onInput Url ] []
                , input [ type_ "checkbox", id "oration-preview-check", defaultValue storedPreview, onClick Preview ] []
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


getValue : String -> Model -> String
getValue value model =
    case Dict.get value model.values of
        Just val ->
            val

        Nothing ->
            ""
