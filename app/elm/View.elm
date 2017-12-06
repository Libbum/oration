module View exposing (view)

import Data.Comment exposing (Comment, Responses(Responses), count)
import Data.User exposing (User, getIdentity)
import Html exposing (..)
import Html.Attributes exposing (autocomplete, checked, cols, defaultValue, disabled, for, href, method, minlength, name, placeholder, rows, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Identicon exposing (identicon)
import Markdown
import Maybe.Extra exposing ((?), isJust)
import Models exposing (Model)
import Msg exposing (Msg(..))
import Style
import Time.DateTime.Distance exposing (inWords)
import Util exposing (nothing)


{- Sync up stylsheets -}


{ id, class, classList } =
    Style.orationNamespace


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
    div [ id Style.Oration ]
        [ h2 [] [ text count ]
        , commentForm model Style.OrationForm
        , div [ id Style.OrationDebug ] [ text model.debug ]
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
                if isJust model.parent then
                    ""
                else
                    model.comment
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



{- Renders comments to markdown -}


markdownContent : String -> Bool -> String
markdownContent content preview =
    if preview then
        content
    else
        ""



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

        commentId =
            "comment-" ++ toString comment.id

        headerStyle =
            if comment.hash == model.blogAuthor then
                [ Style.Thread, Style.BlogAuthor ]
            else
                [ Style.Thread ]

        contentStyle =
            if comment.visible then
                [ Style.Content ]
            else
                [ Style.Hidden ]

        visibleButtonText =
            if comment.visible then
                "[–]"
            else
                "[+" ++ toString (count <| List.singleton comment) ++ "]"
    in
    li [ id commentId, class headerStyle ]
        [ span [ class [ Style.Identicon ] ] [ identicon "25px" comment.hash ]
        , printAuthor author
        , span [ class [ Style.Spacer ] ] [ text "•" ]
        , span [ class [ Style.Date ] ] [ text created ]
        , button [ class [ Style.Toggle ], onClick (ToggleCommentVisibility comment.id) ] [ text visibleButtonText ]
        , div [ class contentStyle ] <|
            Markdown.toHtml Nothing comment.text
                ++ [ printFooter model.parent comment
                   , replyForm comment.id model.parent model
                   , printResponses comment.children model
                   ]
        ]


printAuthor : String -> Html Msg
printAuthor author =
    if String.startsWith "http://" author || String.startsWith "https://" author then
        a [ class [ Style.Author ], href author ] [ text author ]
    else
        span [ class [ Style.Author ] ] [ text author ]


printFooter : Maybe Int -> Comment -> Html Msg
printFooter parent comment =
    let
        replyText =
            if parent == Just comment.id then
                "close"
            else
                "reply"

        edit =
            if comment.editable then
                button [ onClick (CommentEdit comment.id) ] [ text "edit" ]
            else
                nothing

        delete =
            if comment.editable then
                button [ onClick (CommentDelete comment.id) ] [ text "delete" ]
            else
                nothing
    in
    span [ class [ Style.Footer ] ]
        [ edit
        , delete
        , button [ onClick (CommentReply comment.id) ] [ text replyText ]
        ]


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
