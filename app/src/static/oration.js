var Elm = require('../elm/Main');
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

    function setStore(state, location) {
        if (state) {
            localStorage.setItem(location, state);
        } else {
            localStorage.removeItem(location, state);
        }
    }

    var name = localStorage.getItem('orationName');
    var email = localStorage.getItem('orationEmail');
    var url = localStorage.getItem('orationUrl');
    var preview = localStorage.getItem('orationPreview');

    app.ports.title.send(closestTitle(elmDiv));
    app.ports.name.send(name);
    app.ports.email.send(email);
    app.ports.url.send(url);
    app.ports.preview.send(preview);

    app.ports.setName.subscribe(function(state) { setStore(state, 'orationName'); });
    app.ports.setEmail.subscribe(function(state) { setStore(state, 'orationEmail'); });
    app.ports.setUrl.subscribe(function(state) { setStore(state, 'orationUrl'); });
    app.ports.setPreview.subscribe(function(state) { setStore(state, 'orationPreview'); });
}
