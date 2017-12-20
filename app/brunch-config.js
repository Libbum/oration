exports.config = {
    files: {
        javascripts: {
            joinTo: "js/oration.js"
        }
    },
    conventions: {
        assets: /^(static)/,
        ignored: /elm-stuff/
    },
    paths: {
        watched: ["static", "js", "css", "elm"],
        public: "../public"
    },
    plugins: {
        babel: {
            // Do not use ES6 transpiler for debugging
            ignore: [/main.js$/]
        },
        elmBrunch: {
            elmFolder: "elm",
            mainModules: ["Main.elm"],
            makeParameters: ["--warn","--debug"],
            outputFolder: "../js"
        }
    }
};
