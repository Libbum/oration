module View exposing (view)

import Crypto.Hash
import Data.User as User exposing (User)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Identicon exposing (identicon)
import Markdown
import Maybe.Extra exposing ((?), isNothing)
import Models exposing (Model)
import Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
    let
        identity =
            getIdentity model.user

        markdown =
            markdownContent model.comment model.user.preview

        count =
            toString model.count
                ++ (if model.count /= 1 then
                        " comments"
                    else
                        " comment"
                   )

        name_ =
            model.user.name ? ""

        email_ =
            model.user.email ? ""

        url_ =
            model.user.url ? ""
    in
    div [ id "oration" ]
        [ h2 [] [ text count ]
        , Html.form [ method "post", id "oration-form", onSubmit PostComment ]
            [ textarea [ name "comment", placeholder "Write a comment here (min 3 characters).", value model.comment, minlength 3, cols 55, rows 4, onInput Comment ] []
            , div [ id "oration-control" ]
                [ span [ id "oration-identicon" ] [ identicon "25px" identity ]
                , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue name_, autocomplete True, onInput Name ] []
                , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue email_, autocomplete True, onInput Email ] []
                , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue url_, onInput Url ] []
                , input [ type_ "checkbox", id "oration-preview-check", checked model.user.preview, onClick Preview ] []
                , label [ for "oration-preview-check" ] [ text "Preview" ]
                , input [ type_ "submit", class "oration-submit", disabled <| setDisabled model.comment, value "Comment", onClick StoreUser ] []
                ]
            ]
        , div [ id "debug" ] [ text model.httpResponse ]
        , div [ id "comment-preview" ] <|
            Markdown.toHtml Nothing markdown
        ]


setDisabled : String -> Bool
setDisabled comment =
    if String.length comment > 3 then
        False
    else
        True


markdownContent : String -> Bool -> String
markdownContent content preview =
    if preview then
        content
    else
        ""


getIdentity : User -> String
getIdentity user =
    let
        data =
            [ user.name ? "", user.email ? "", user.url ? "" ]
    in
    if List.all String.isEmpty data then
        user.iphash ? ""
    else
        Crypto.Hash.sha224 (String.join "b" data)



--Join with b since it gives the authors' credentials a cool identicon
