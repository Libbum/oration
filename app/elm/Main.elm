module Main exposing (..)

import Html exposing (Attribute, Html)
import Html.Attributes as HA
import Html.Events as HE
import Identicon exposing (identicon)


main =
    Html.beginnerProgram
        { model = init
        , update = update
        , view = view
        }


type alias Model =
    String


init : Model
init =
    "Hello!"


type alias Msg =
    String


update : Msg -> Model -> Model
update text model =
    text


view : Model -> Html Msg
view model =
    let
        field =
            Html.input
                [ HA.placeholder "Enter a string..."
                , HE.onInput identity
                , inputStyle
                ]
                []

        icon =
            Html.div [ iconStyle ] [ identicon "200px" model ]
    in
    Html.div [] [ field, icon ]


inputStyle : Attribute Msg
inputStyle =
    HA.style
        [ ( "width", "100%" )
        , ( "height", "40px" )
        , ( "padding", "10px 0" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ]


iconStyle : Attribute Msg
iconStyle =
    HA.style
        [ ( "width", "200px" )
        , ( "height", "200px" )
        , ( "padding", "50px 0" )
        , ( "margin", "auto" )
        , ( "font-size", "2em" )
        , ( "text-align", "center" )
        ]
