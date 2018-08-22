module View exposing (view)

import Data.Comment exposing (Comment, Responses(..), count)
import Data.User exposing (Identity, getIdentity)
import Html exposing (..)
import Html.Attributes exposing (autocomplete, checked, cols, defaultValue, disabled, for, href, method, minlength, name, placeholder, rows, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Identicon exposing (identicon)
import Markdown exposing (defaultOptions)
import Maybe.Extra exposing ((?), isJust, isNothing)
import Models exposing (Model, Status(..))
import Msg exposing (Msg(..))
import Style
import Time.DateTime.Distance exposing (inWords)
import Util exposing (nothing, stringToMaybe)



{- Sync up stylsheets -}


{ id, class, classList } =
    Style.orationNamespace


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
    div [ id Style.Oration ]
        [ h2 [] [ text count ]
        , commentForm model Nothing
        , ul [ id Style.OrationComments ] <| printComments model
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
                    Style.OrationForm

                _ ->
                    Style.OrationReplyForm

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
                Markdown.toHtmlWith options [ id Style.OrationCommentPreview ] <|
                    markdownContent model.comment model.user.preview
    in
    Html.form [ method "post", id formID, class [ Style.Form ], onSubmit submitCmd ]
        [ textarea
            [ name "comment"
            , placeholder "Write a comment here (min 3 characters)."
            , value textAreaValue
            , minlength 3
            , cols 80
            , rows 4
            , onInput UpdateComment
            , disabled formDisable
            , class [ Style.Block ]
            ]
            []
        , div [ class [ Style.User ] ]
            [ span [ class [ Style.Identicon, Style.LeftMargin10 ] ] [ identicon "25px" identity ]
            , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue name_, autocomplete True, onInput (\name -> UpdateName <| stringToMaybe name) ] []
            , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue email_, autocomplete True, onInput (\email -> UpdateEmail <| stringToMaybe email) ] []
            , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue url_, onInput (\url -> UpdateUrl <| stringToMaybe url) ] []
            ]
        , div [ class [ Style.Control ] ]
            [ input [ type_ "checkbox", id Style.OrationPreviewCheck, checked model.user.preview, onClick UpdatePreview ] []
            , label [ for (toString Style.OrationPreviewCheck) ] [ text "Preview" ]
            , input [ type_ "submit", class [ Style.Submit ], disabled buttonDisable, value submitText, onClick StoreUser ] []
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
                [ Style.Thread, Style.BlogAuthor ]

            else
                [ Style.Thread ]

        contentStyle =
            if comment.visible then
                [ Style.Comment ]

            else
                [ Style.Hidden ]

        visibleButtonText =
            if comment.visible then
                "[–]"

            else
                "[+" ++ toString (count <| List.singleton comment) ++ "]"
    in
    if notDeleted then
        li [ id commentId, class headerStyle ]
            [ span [ class [ Style.Identicon ] ] [ identicon "25px" comment.hash ]
            , printAuthor author
            , span [ class [ Style.Spacer ] ] [ text "•" ]
            , span [ class [ Style.Date ] ] [ text created ]
            , button [ class [ Style.Toggle ], onClick (ToggleCommentVisibility comment.id) ] [ text visibleButtonText ]
            , div [ class contentStyle ]
                [ Markdown.toHtmlWith options [ class [ Style.Content ] ] comment.text
                , printFooter model.status model.user.identity comment
                , replyForm comment.id model
                , printResponses comment.children model
                ]
            ]

    else
        li [ id commentId, class headerStyle ]
            [ span [ class [ Style.Deleted ] ] [ text "Deleted comment" ]
            , span [ class [ Style.Spacer ] ] [ text "•" ]
            , span [ class [ Style.Date ] ] [ text created ]
            , button [ class [ Style.Toggle ], onClick (ToggleCommentVisibility comment.id) ] [ text visibleButtonText ]
            , div [ class contentStyle ] [ printResponses comment.children model ]
            ]


printAuthor : String -> Html Msg
printAuthor author =
    if String.startsWith "http://" author || String.startsWith "https://" author then
        a [ class [ Style.Author ], href author ] [ text author ]

    else
        span [ class [ Style.Author ] ] [ text author ]


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
                button [ onClick (CommentEdit comment.id), disabled editDisabled ] [ text editText ]

            else
                nothing

        delete =
            if comment.editable then
                button [ onClick (CommentDelete comment.id), disabled deleteDisabled ] [ text "delete" ]

            else
                nothing

        votes =
            if comment.votes == 0 then
                " "

            else
                " " ++ toString comment.votes
    in
    span [ class [ Style.Footer ] ]
        [ span [ class [ Style.Votes ] ]
            [ button [ onClick (CommentLike comment.id), disabled votingDisabled ] [ text "⮝" ]
            , button [ onClick (CommentDislike comment.id), disabled votingDisabled ] [ text "⮟" ]
            , text votes
            ]
        , button [ onClick (CommentReply comment.id), disabled replyDisabled ] [ text replyText ]
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
