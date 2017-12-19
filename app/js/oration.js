import Elm from './main';
const elmDiv = document.getElementById('comments');
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

    var name = localStorage.getItem('name');
    var email = localStorage.getItem('email');
    var url = localStorage.getItem('url');
    var preview = localStorage.getItem('preview');

    app.ports.title.send(closestTitle(elmDiv));
    app.ports.name.send(name);
    app.ports.email.send(email);
    app.ports.url.send(url);
    app.ports.preview.send(preview);

    app.ports.setName.subscribe(function(state) {
        localStorage.setItem('name', state);
    });
    app.ports.setEmail.subscribe(function(state) {
        localStorage.setItem('email', state);
    });
    app.ports.setUrl.subscribe(function(state) {
        localStorage.setItem('url', state);
    });
    app.ports.setPreview.subscribe(function(state) {
        localStorage.setItem('preview', state);
    });
}
