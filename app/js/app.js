import Elm from './main';
const elmDiv = document.querySelector('#elm-container');
if (elmDiv) {
    var app = Elm.Main.embed(elmDiv);
    app.ports.title.send(document.title);
}
