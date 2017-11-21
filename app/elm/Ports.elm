port module Ports exposing (email, name, preview, setEmail, setName, setPreview, setUrl, title, url)

{- port for listening for document title from JavaScript -}


port title : (String -> msg) -> Sub msg



{- Get name from localStorage -}


port name : (String -> msg) -> Sub msg


port setName : String -> Cmd msg



{- Get email from localStorage -}


port email : (String -> msg) -> Sub msg


port setEmail : String -> Cmd msg



{- Get url from localStorage -}


port url : (String -> msg) -> Sub msg


port setUrl : String -> Cmd msg



{- Get preview option from localStorage -}


port preview : (String -> msg) -> Sub msg


port setPreview : String -> Cmd msg
