exports.config = {
    files: {
        javascripts: {
            joinTo: "js/app.js"
        },
        stylesheets: {
            joinTo: "css/oration.css"
        }
    },
    conventions: {
        // This option sets where we should place non-css and non-js assets in.
        // By default, we set this to "/assets/static". Files in this directory
        // will be copied to `paths.public`, which is set below to "../public".
        assets: /^(static)/
    },
    // paths configuration
    paths: {
        // Dependencies and current project directories to watch
        watched: ["static", "css", "js", "vendor", "elm"],
        // Where to compile files to
        public: "../public"
    },
    plugins: {
        babel: {
            // Do not use ES6 compiler in vendor code
            ignore: [/vendor/]
        },
        elmBrunch: {
            elmFolder: "elm",
            mainModules: ["Main.elm"],
            makeParameters: ['--warn','--debug'],
            outputFolder: "../js"
        },
    },
    modules: {
        autoRequire: {
            "js/app.js": ["js/app"]
        }
    }
};
