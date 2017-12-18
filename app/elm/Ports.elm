port module Ports exposing (email, name, preview, setEmail, setName, setPreview, setUrl, title, url)

{- port for listening for document title from JavaScript -}


port title : (String -> msg) -> Sub msg



{- Get name from localStorage -}


port name : (Maybe String -> msg) -> Sub msg


port setName : String -> Cmd msg



{- Get email from localStorage -}


port email : (Maybe String -> msg) -> Sub msg


port setEmail : String -> Cmd msg



{- Get url from localStorage -}


port url : (Maybe String -> msg) -> Sub msg


port setUrl : String -> Cmd msg



{- Get preview option from localStorage -}


port preview : (Maybe String -> msg) -> Sub msg


port setPreview : String -> Cmd msg
