module View exposing (view)

import Crypto.Hash
import Data.Comment exposing (Comment)
import Data.User exposing (User)
import Date
import Date.Distance exposing (defaultConfig, inWordsWithConfig)
import Date.Distance.I18n.En as English
import Date.Distance.Types exposing (Config)
import Date.Extra.Create exposing (getTimezoneOffset)
import Date.Extra.Period as Period exposing (Period(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Identicon exposing (identicon)
import Markdown
import Maybe.Extra exposing ((?), isJust, isNothing)
import Models exposing (Model)
import Msg exposing (Msg(..))
import Util exposing (nothing)


view : Model -> Html Msg
view model =
    let
        markdown =
            markdownContent model.comment model.user.preview

        count =
            toString model.count
                ++ (if model.count /= 1 then
                        " comments"
                    else
                        " comment"
                   )
    in
    div [ id "oration" ]
        [ h2 [] [ text count ]
        , commentForm model "oration-form"
        , div [ id "debug" ] [ text model.httpResponse ]
        , div [ id "comment-preview" ] <|
            Markdown.toHtml Nothing markdown
        , div [ id "oration-comments" ] <| printComments model
        ]



{- Comment form. Can be used as the main form or in a reply. -}


commentForm : Model -> String -> Html Msg
commentForm model formID =
    let
        identity =
            getIdentity model.user

        name_ =
            model.user.name ? ""

        email_ =
            model.user.email ? ""

        url_ =
            model.user.url ? ""

        textAreaValue =
            if formID == "oration-form" then
                if isNothing model.parent then
                    model.comment
                else
                    ""
            else
                --reply-form
                model.comment

        textAreaDisable =
            if formID == "oration-form" && isJust model.parent then
                True
            else
                False

        buttonDisable =
            if textAreaDisable then
                True
            else
                setButtonDisabled model.comment
    in
    Html.form [ method "post", id formID, onSubmit PostComment ]
        [ textarea
            [ name "comment"
            , placeholder "Write a comment here (min 3 characters)."
            , value textAreaValue
            , minlength 3
            , cols 55
            , rows 4
            , onInput UpdateComment
            , disabled textAreaDisable
            ]
            []
        , div [ id "oration-control" ]
            [ span [ id "oration-identicon" ] [ identicon "25px" identity ]
            , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue name_, autocomplete True, onInput UpdateName ] []
            , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue email_, autocomplete True, onInput UpdateEmail ] []
            , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue url_, onInput UpdateUrl ] []
            , input [ type_ "checkbox", id "oration-preview-check", checked model.user.preview, onClick UpdatePreview ] []
            , label [ for "oration-preview-check" ] [ text "Preview" ]
            , input [ type_ "submit", class "oration-submit", disabled buttonDisable, value "Comment", onClick StoreUser ] []
            ]
        ]



{- Only allows users to comment if their comment is longer than 3 characters -}


setButtonDisabled : String -> Bool
setButtonDisabled comment =
    if String.length comment > 3 then
        False
    else
        True



{- Renders comments to markdown -}


markdownContent : String -> Bool -> String
markdownContent content preview =
    if preview then
        content
    else
        ""



{- Hashes user information depending on available data -}


getIdentity : User -> String
getIdentity user =
    let
        data =
            [ user.name, user.email, user.url ]

        --I think Maybe.Extra.values could also be used here
        unwrapped =
            List.filterMap identity data
    in
    if List.all isNothing data then
        user.iphash ? ""
    else
        -- Join with b since it gives the authors' credentials a cool identicon
        Crypto.Hash.sha224 (String.join "b" unwrapped)



{- We work in UTC, so offset the users time so we can compare dates -}


offsetNow : Maybe Date.Date -> Maybe Date.Date
offsetNow now =
    let
        offsetMinutes =
            Maybe.map getTimezoneOffset now
    in
    Maybe.map (\d -> Period.add Period.Minute (offsetMinutes ? 0) d) now



{- Format a list of comments -}


printComments : Model -> List (Html Msg)
printComments model =
    let
        utcNow =
            offsetNow model.now
    in
    List.map (\c -> printComment c utcNow model) model.comments



{- Format a single comment
   For now this ignores parent nesting.
-}


printComment : Comment -> Maybe Date.Date -> Model -> Html Msg
printComment comment now model =
    let
        author =
            comment.author ? "Anonymous"

        created =
            --TODO: Can this be chained?
            case comment.created of
                Just val ->
                    case now of
                        Just time ->
                            inWordsWithConfig wordsConfig time val

                        Nothing ->
                            ""

                Nothing ->
                    ""

        id =
            toString comment.id

        buttonText =
            if model.parent == Just comment.id then
                "close"
            else
                "reply"
    in
    div [ name ("comment-" ++ id), class "comment" ]
        [ span [ class "identicon" ] [ identicon "25px" comment.hash ]
        , span [ class "author" ] [ text author ]
        , span [ class "date" ] [ text created ]
        , span [ class "text" ] <| Markdown.toHtml Nothing comment.text
        , button [ onClick (CommentReply comment.id) ] [ text buttonText ]
        , replyForm comment.id model.parent model
        ]


replyForm : Int -> Maybe Int -> Model -> Html Msg
replyForm id parent model =
    case parent of
        Just val ->
            if id == val then
                commentForm model "reply-form"
            else
                nothing

        Nothing ->
            nothing



{- We want to add a suffix onto our word distances.
   This is how you do that. Not very nice, but we can extend the locale portion later this way
-}


wordsConfig : Config
wordsConfig =
    let
        localeWithSuffix =
            English.locale { addSuffix = True }
    in
    { defaultConfig | locale = localeWithSuffix }
