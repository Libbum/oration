import Elm from './main';
const elmDiv = document.getElementById('elm-container');
if (elmDiv) {
    var app = Elm.Main.embed(elmDiv);

    function closestTitle(el) {
        var previous;
        // traverse previous elements to look for a h1
        while (el) {
            previous = el.previousElementSibling;
            if (previous && previous.tagName == "H1") {
                return previous.innerText;
            }
            el = previous;
        }
        return document.title; //If not found, use the page title
    }

    app.ports.title.send(closestTitle(elmDiv));
}
