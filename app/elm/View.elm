module View exposing (view)

import Crypto.Hash
import Data.Comment exposing (Comment, Responses(Responses), count)
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
        , div [ id Style.OrationDebug ] [ text model.httpResponse ]
        , div [ id Style.OrationCommentPreview ] <|
            Markdown.toHtml Nothing markdown
        , ul [ id Style.OrationComments ] <| printComments model
        ]



{- Comment form. Can be used as the main form or in a reply. -}


type alias CommentFormModel =
    { identity : String
    , name : String
    , email : String
    , url : String
    , textAreaValue : String
    , textAreaDisable : Bool
    , buttonDisable : Bool
    , id : Style.OrationIds
    , preview : Bool
    }


commentFormSelector : Model -> Style.OrationIds -> CommentFormModel
commentFormSelector model formId =
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
            if formId == Style.OrationForm then
                if isNothing model.parent then
                    model.comment
                else
                    ""
            else
                --OrationReplyForm
                model.comment

        textAreaDisable =
            if formId == Style.OrationForm && isJust model.parent then
                True
            else
                False

        buttonDisable =
            if textAreaDisable then
                True
            else
                setButtonDisabled model.comment
    in
    { identity = getIdentity model.user
    , name = model.user.name ? ""
    , email = model.user.email ? ""
    , url = model.user.url ? ""
    , textAreaValue = textAreaValue
    , textAreaDisable = textAreaDisable
    , buttonDisable = buttonDisable
    , id = formId
    , preview = model.user.preview
    }


commentFormView : CommentFormModel -> Html Msg
commentFormView cfm =
    Html.form [ method "post", id cfm.id, class [ Style.Form ], onSubmit PostComment ]
        [ textarea
            [ name "comment"
            , placeholder "Write a comment here (min 3 characters)."
            , value cfm.textAreaValue
            , minlength 3
            , cols 80
            , rows 4
            , onInput UpdateComment
            , disabled cfm.textAreaDisable
            , class [ Style.Block ]
            ]
            []
        , div [ class [ Style.User ] ]
            [ span [ class [ Style.Identicon, Style.LeftMargin10 ] ] [ identicon "25px" cfm.identity ]
            , input [ type_ "text", name "name", placeholder "Name (optional)", defaultValue cfm.name, autocomplete True, onInput UpdateName ] []
            , input [ type_ "email", name "email", placeholder "Email (optional)", defaultValue cfm.email, autocomplete True, onInput UpdateEmail ] []
            , input [ type_ "url", name "url", placeholder "Website (optional)", defaultValue cfm.url, onInput UpdateUrl ] []
            ]
        , div [ class [ Style.Control ] ]
            [ input [ type_ "checkbox", id Style.OrationPreviewCheck, checked cfm.preview, onClick UpdatePreview ] []
            , label [ for (toString Style.OrationPreviewCheck) ] [ text "Preview" ]
            , input [ type_ "submit", class [ Style.Submit ], disabled cfm.buttonDisable, value "Comment", onClick StoreUser ] []
            ]
        ]


commentForm : Model -> Style.OrationIds -> Html Msg
commentForm model id =
    commentFormView <| commentFormSelector model id



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



{- Format a list of comments -}


printComments : Model -> List (Html Msg)
printComments model =
    List.map (\c -> printComment c model) model.comments



{- Format a single comment -}


type alias PrintCommentModel =
    { author : String
    , hash : String
    , created : String
    , id : Int
    , parent : Maybe Int
    , children : Responses
    , text : String
    , buttonText : String
    , headerStyle : List Style.OrationClasses
    , contentStyle : List Style.OrationClasses
    , visibleButtonText : String
    }


printCommentSelector : Comment -> Model -> PrintCommentModel
printCommentSelector comment model =
    let
        buttonText =
            if model.parent == Just comment.id then
                "close"
            else
                "reply"

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
    { author = comment.author ? "Anonymous"
    , hash = comment.hash
    , created = inWords model.now comment.created
    , id = comment.id
    , parent = model.parent
    , children = comment.children
    , text = comment.text
    , buttonText = buttonText
    , headerStyle = headerStyle
    , contentStyle = contentStyle
    , visibleButtonText = visibleButtonText
    }


printCommentView : PrintCommentModel -> Html Msg
printCommentView cm =
    li [ name ("comment-" ++ toString cm.id), class cm.headerStyle ]
        [ span [ class [ Style.Identicon ] ] [ identicon "25px" cm.hash ]
        , printAuthor cm.author
        , span [ class [ Style.Spacer ] ] [ text "•" ]
        , span [ class [ Style.Date ] ] [ text cm.created ]
        , button [ class [ Style.Toggle ], onClick (ToggleCommentVisibility cm.id) ] [ text cm.visibleButtonText ]
        , div [ class cm.contentStyle ] <|
            Markdown.toHtml Nothing cm.text
                ++ [ button [ onClick (CommentReply cm.id), class [ Style.Reply ] ] [ text cm.buttonText ]
                   , replyForm cm.id cm.parent

                   --, printResponses cm.children
                   ]
        ]


printComment : Comment -> Model -> Html Msg
printComment comment model =
    printCommentView <| printCommentSelector comment model


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
