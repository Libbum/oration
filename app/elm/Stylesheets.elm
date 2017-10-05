port module Stylesheets exposing (..)

import Css.File exposing (CssCompilerProgram, CssFileStructure)
import Style


{- Stylesheets -}


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "oration.css", Css.File.compile [ Style.css ] ) ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
