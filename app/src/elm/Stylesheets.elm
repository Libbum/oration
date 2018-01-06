port module Stylesheets exposing (..)

import Css.File exposing (CssCompilerProgram, CssFileStructure)
import Css.Normalize
import Style


{- Stylesheets -}


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "main.css", Css.File.compile [ Css.Normalize.css, Style.css ] ) ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
