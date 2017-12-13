var _Libbum$oration$Native_Markdown = function() {


    // VIRTUAL-DOM WIDGETS

    function toHtml(options, factList, rawMarkdown)
    {
        var model = {
            options: options,
            markdown: rawMarkdown
        };
        return _elm_lang$virtual_dom$Native_VirtualDom.custom(factList, model, implementation);
    }


    // WIDGET IMPLEMENTATION

    var implementation = {
        render: render,
        diff: diff
    };

    function render(model)
    {
        var html = parse(model.markdown, formatOptions(model.options));
        var div = document.createElement('div');
        div.innerHTML = html;
        return div;
    }

    function diff(a, b)
    {
        if (a.model.markdown === b.model.markdown && a.model.options === b.model.options)
        {
            return null;
        }

        return {
            applyPatch: applyPatch,
            data: parse(b.model.markdown, formatOptions(b.model.options))
        };
    }

    function applyPatch(domNode, data)
    {
        domNode.innerHTML = data;
        return domNode;
    }


    // ACTUAL MARKDOWN PARSER

    var parse = function() {
        // catch the parser object regardless of the outer environment.
        // (ex. a CommonJS module compatible environment.)
        // note that this depends on markdown-it's implementation of environment detection.
        var module = {};
        var exports = module.exports = {};

        // markdown-it 8.4.0 https://github.com//markdown-it/markdown-it @license MIT
        // markdown-it-katex 2.0.3 https://github.com/waylonflinn/markdown-it-katex/ @license MIT
        return function (text, options) {
            var md = require('markdown-it')(options.preset, options),
                mk = require('markdown-it-katex');
            md.use(mk);
            return md.render(text);
        };
    }();


    // FORMAT OPTIONS FOR PARSER IMPLEMENTATION

    function formatOptions(options) {

        function toHighlight(code, lang) {
            if (!lang && options.defaultHighlighting.ctor === 'Just') {
                lang = options.defaultHighlighting._0;
            }

            if (typeof hljs !== 'undefined' && lang && hljs.listLanguages().indexOf(lang) >= 0) {
                return hljs.highlight(lang, code, true).value;
            }

            return code;
        }

        options.highlight = toHighlight;

        // assign all 'Just' values and delete all 'Nothing' values
        for (var key in options) {
            var val = options[key];
            if (!val) {
                continue;
            }
            if (val.ctor === 'Just') {
                options[key] = val._0;
            } else if (val.ctor === 'Nothing') {
                delete options[key];
            }
        }

        if (options.githubFlavored) {
            options.preset = 'default';
        } else {
            options.preset = 'commonmark';
        }

        if (options.quotes) {
            options.quotes =
                [ options.quotes.doubleLeft
                    , options.quotes.doubleRight
                    , options.quotes.singleLeft
                    , options.quotes.singleRight
                ];
        }

        return options;
    }


    // EXPORTS

    return {
        toHtml: F3(toHtml)
    };

}();
