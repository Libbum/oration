module View exposing (view)

import Crypto.Hash
import Data.Comment exposing (Comment, Responses(Responses))
import Data.User exposing (User)
import Html exposing (..)
import Html.Attributes exposing (autocomplete, checked, cols, defaultValue, disabled, for, href, method, minlength, name, placeholder, rows, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Identicon exposing (identicon)
import Markdown
import Maybe.Extra exposing ((?), isJust, isNothing)
import Models exposing (Model)
import Msg exposing (Msg(..))
import Style
import Time.DateTime.Distance exposing (inWords)
import Util exposing (nothing, parseMath)


{- Sync up stylsheets -}


{ id, class, classList } =
    Style.orationNamespace


view : Model -> Html Msg
view model =
    let
        markdown =
            markdownContent model.comment model.user.preview
                |> String.lines
                |> parseMath
                >> String.join "\n"

        count =
            toString model.count
                ++ (if model.count /= 1 then
                        " comments"
                    else
                        " comment"
                   )
    in
    div [ id Style.Oration ]
        [ h2 [] [ text count ]
        , commentForm model Style.OrationForm
        , div [ id Style.OrationDebug ] [ text model.httpResponse ]
        , div [ id Style.OrationCommentPreview ] <|
            Markdown.toHtml Nothing markdown
        , ul [ id Style.OrationComments ] <| printComments model
        ]



{- Comment form. Can be used as the main form or in a reply. -}


commentForm : Model -> Style.OrationIds -> Html Msg
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
            if formID == Style.OrationForm then
                if isNothing model.parent then
                    model.comment
                else
                    ""
            else
                --OrationReplyForm
                model.comment

        textAreaDisable =
            if formID == Style.OrationForm && isJust model.parent then
                True
            else
                False

        buttonDisable =
            if textAreaDisable then
                True
            else
                setButtonDisabled model.comment
    in
    Html.form [ method "post", id formID, class [ Style.Form ], onSubmit PostComment ]
        [ textarea
            [ name "comment"
            , placeholder "Write a comment here (min 3 characters)."
            , value textAreaValue
            , minlength 3
            , cols 80
            , rows 4
            , onInput UpdateComment
            , disabled textAreaDisable
            , class [ Style.Block ]
            ]
            []
        , div [ class [ Style.User ] ]
            [ span [ class [ Style.Identicon, Style.LeftMargin10 ] ] [ identicon "25px" identity ]
            , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue name_, autocomplete True, onInput UpdateName ] []
            , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue email_, autocomplete True, onInput UpdateEmail ] []
            , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue url_, onInput UpdateUrl ] []
            ]
        , div [ class [ Style.Control ] ]
            [ input [ type_ "checkbox", id Style.OrationPreviewCheck, checked model.user.preview, onClick UpdatePreview ] []
            , label [ for (toString Style.OrationPreviewCheck) ] [ text "Preview" ]
            , input [ type_ "submit", class [ Style.Submit ], disabled buttonDisable, value "Comment", onClick StoreUser ] []
            ]
        ]



{- Only allows users to comment if their comment is longer than 3 characters -}


setButtonDisabled : String -> Bool
setButtonDisabled comment =
    if String.length comment > 3 then
        False
    else
        True



{- Markdown preview box information -}


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



{- Format a list of comments -}


printComments : Model -> List (Html Msg)
printComments model =
    List.map (\c -> printComment c model) model.comments



{- Format a single comment -}


printComment : Comment -> Model -> Html Msg
printComment comment model =
    let
        author =
            comment.author ? "Anonymous"

        created =
            inWords model.now comment.created

        id =
            toString comment.id

        buttonText =
            if model.parent == Just comment.id then
                "close"
            else
                "reply"

        commentStyle =
            if comment.hash == model.blogAuthor then
                [ Style.Comment, Style.BlogAuthor ]
            else
                [ Style.Comment ]
    in
    li [ name ("comment-" ++ id), class commentStyle ]
        [ span [ class [ Style.Identicon ] ] [ identicon "25px" comment.hash ]
        , printAuthor author
        , span [ class [ Style.Spacer ] ] [ text "•" ]
        , span [ class [ Style.Date ] ] [ text created ]
        , span [ class [ Style.Content ] ] <| Markdown.toHtml Nothing comment.text
        , button [ onClick (CommentReply comment.id), class [ Style.Reply ] ] [ text buttonText ]
        , replyForm comment.id model.parent model
        , printResponses comment.children model
        ]


printAuthor : String -> Html Msg
printAuthor author =
    if String.startsWith "http://" author || String.startsWith "https://" author then
        a [ class [ Style.Author ], href author ] [ text author ]
    else
        span [ class [ Style.Author ] ] [ text author ]


printResponses : Responses -> Model -> Html Msg
printResponses (Responses responses) model =
    ul [] <|
        List.map (\c -> printComment c model) responses


replyForm : Int -> Maybe Int -> Model -> Html Msg
replyForm id parent model =
    case parent of
        Just val ->
            if id == val then
                commentForm model Style.OrationReplyForm
            else
                nothing

        Nothing ->
            nothing
