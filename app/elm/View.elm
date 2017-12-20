module View exposing (view)

import Data.Comment exposing (Comment, Responses(Responses), count)
import Data.User exposing (Identity, getIdentity)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (autocomplete, checked, cols, css, defaultValue, disabled, for, href, id, method, minlength, name, placeholder, rows, type_, value)
import Html.Styled.Events exposing (onClick, onInput, onSubmit)
import Identicon exposing (identicon)
import Markdown exposing (defaultOptions)
import Maybe.Extra exposing ((?), isJust, isNothing)
import Models exposing (Model, Status(..))
import Msg exposing (Msg(..))
import Style exposing (commentArea, footerButton, userInput)
import Time.DateTime.Distance exposing (inWords)
import Util exposing (nothing)


view : Model -> Html Msg
view model =
    let
        count =
            toString model.count
                ++ (if model.count /= 1 then
                        " comments"
                    else
                        " comment"
                   )
    in
    div [ id "Oration", css Style.oration ]
        [ h2 [] [ text count ]
        , commentForm model Nothing
        , ul [ id "OrationComments", css Style.orationComments ] <| printComments model
        ]



{- Comment form. Can be used as the main form or in a reply. -}


commentForm : Model -> Maybe Int -> Html Msg
commentForm model commentId =
    let
        -- Even though we have model.user.identity, this is a semi-persistent copy
        -- for editing and deleting authorisation. Here, we want up-to-date identicons
        identity =
            getIdentity model.user

        name_ =
            model.user.name ? ""

        email_ =
            model.user.email ? ""

        url_ =
            model.user.url ? ""

        textAreaValue =
            case model.status of
                Commenting ->
                    if isNothing model.parent then
                        model.comment
                    else
                        ""

                _ ->
                    model.comment

        formID =
            case model.status of
                Commenting ->
                    "OrationForm"

                _ ->
                    "OrationReplyForm"

        formDisable =
            if isNothing commentId && isJust model.parent then
                True
            else
                False

        buttonDisable =
            if formDisable then
                True
            else
                setButtonDisabled model.comment

        submitText =
            if isNothing commentId then
                "Comment"
                --The main form is never a reply or update
            else
                case model.status of
                    Commenting ->
                        "Comment"

                    Editing ->
                        "Update"

                    Replying ->
                        "Reply"

        submitCmd =
            case model.status of
                Editing ->
                    SendEdit (commentId ? -1)

                _ ->
                    PostComment

        preview =
            if formDisable then
                nothing
            else
                Markdown.toHtmlWith options [ id "OrationCommentPreview" ] <|
                    markdownContent model.comment model.user.preview
    in
    Html.Styled.form [ method "post", id formID, css Style.form, onSubmit submitCmd ]
        [ commentArea
            [ name "comment"
            , placeholder "Write a comment here (min 3 characters)."
            , value textAreaValue
            , minlength 3
            , cols 80
            , rows 4
            , onInput UpdateComment
            , disabled formDisable
            ]
            []
        , div [ css Style.user ]
            [ span [ css <| Style.identicon ++ Style.leftMargin10 ] [ fromUnstyled <| identicon "25px" identity ]
            , userInput [ type_ "text", name "name", placeholder "Name (optional)", defaultValue name_, autocomplete True, onInput (\name -> UpdateName (Just name)) ] []
            , userInput [ type_ "email", name "email", placeholder "Email (optional)", defaultValue email_, autocomplete True, onInput (\email -> UpdateEmail (Just email)) ] []
            , userInput [ type_ "url", name "url", placeholder "Website (optional)", defaultValue url_, onInput (\url -> UpdateUrl (Just url)) ] []
            ]
        , div [ css Style.control ]
            [ input [ type_ "checkbox", id "OrationPreviewCheck", checked model.user.preview, onClick UpdatePreview ] []
            , label [ for "OrationPreviewCheck" ] [ text "Preview" ]
            , input [ type_ "submit", css Style.submit, disabled buttonDisable, value submitText, onClick StoreUser ] []
            ]
        , preview
        ]



{- Only allows users to comment if their comment is longer than 3 characters -}


setButtonDisabled : String -> Bool
setButtonDisabled comment =
    if String.length comment > 3 then
        False
    else
        True



{- Renders comments to markdown -}


options : Markdown.Options
options =
    { defaultOptions
        | githubFlavored = True
        , breaks = True
        , typographer = True
        , linkify = True
    }


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
        notDeleted =
            if String.isEmpty comment.text && String.isEmpty comment.hash then
                False
            else
                True

        author =
            comment.author ? "Anonymous"

        created =
            inWords model.now comment.created

        commentId =
            "comment-" ++ toString comment.id

        headerStyle =
            if comment.hash == model.blogAuthor && notDeleted then
                [ id commentId, css Style.blogAuthor ]
            else
                [ id commentId ]

        contentStyle =
            if comment.visible then
                Style.comment
            else
                Style.hidden

        visibleButtonText =
            if comment.visible then
                "[–]"
            else
                "[+" ++ toString (count <| List.singleton comment) ++ "]"
    in
    if notDeleted then
        li headerStyle
            [ span [ css Style.identicon ] [ fromUnstyled <| identicon "25px" comment.hash ]
            , printAuthor author
            , span [ css Style.spacer ] [ text "•" ]
            , span [ css Style.date ] [ text created ]
            , button [ css Style.toggle, onClick (ToggleCommentVisibility comment.id) ] [ text visibleButtonText ]
            , div [ css contentStyle ]
                [ Markdown.toHtmlWith options [ css Style.content ] comment.text
                , printFooter model.status model.user.identity comment
                , replyForm comment.id model
                , printResponses comment.children model
                ]
            ]
    else
        li headerStyle
            [ span [ css Style.deleted ] [ text "Deleted comment" ]
            , span [ css Style.spacer ] [ text "•" ]
            , span [ css Style.date ] [ text created ]
            , button [ css Style.toggle, onClick (ToggleCommentVisibility comment.id) ] [ text visibleButtonText ]
            , div [ css contentStyle ] [ printResponses comment.children model ]
            ]


printAuthor : String -> Html Msg
printAuthor author =
    if String.startsWith "http://" author || String.startsWith "https://" author then
        a [ css Style.author, href author ] [ text author ]
    else
        span [ css Style.author ] [ text author ]


printFooter : Status -> Identity -> Comment -> Html Msg
printFooter status identity comment =
    let
        replyText =
            case status of
                Replying ->
                    "close"

                _ ->
                    "reply"

        editText =
            case status of
                Editing ->
                    "close"

                _ ->
                    "edit"

        replyDisabled =
            case status of
                Editing ->
                    True

                _ ->
                    False

        editDisabled =
            case status of
                Replying ->
                    True

                _ ->
                    False

        deleteDisabled =
            case status of
                Commenting ->
                    False

                _ ->
                    True

        votingDisabled =
            if comment.votable && comment.hash /= identity then
                False
            else
                True

        edit =
            if comment.editable then
                footerButton [ onClick (CommentEdit comment.id), disabled editDisabled ] [ text editText ]
            else
                nothing

        delete =
            if comment.editable then
                footerButton [ onClick (CommentDelete comment.id), disabled deleteDisabled ] [ text "delete" ]
            else
                nothing

        votes =
            if comment.votes == 0 then
                " "
            else
                " " ++ toString comment.votes
    in
    span []
        [ span [ css Style.votes ]
            [ footerButton [ onClick (CommentLike comment.id), disabled votingDisabled ] [ text "\xF106" ]
            , footerButton [ onClick (CommentDislike comment.id), disabled votingDisabled ] [ text "\xF107" ]
            , text votes
            ]
        , footerButton [ onClick (CommentReply comment.id), disabled replyDisabled ] [ text replyText ]
        , edit
        , delete
        ]


printResponses : Responses -> Model -> Html Msg
printResponses (Responses responses) model =
    if List.isEmpty responses then
        nothing
    else
        ul [] <|
            List.map (\c -> printComment c model) responses


replyForm : Int -> Model -> Html Msg
replyForm id model =
    case model.status of
        Commenting ->
            nothing

        _ ->
            case model.parent of
                Just val ->
                    if id == val then
                        commentForm model (Just id)
                    else
                        nothing

                Nothing ->
                    nothing
