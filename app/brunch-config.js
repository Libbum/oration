exports.config = {
    files: {
        javascripts: {
            joinTo: "js/oration.js"
        },
        stylesheets: {
            joinTo: "css/oration.css"
        }
    },
    conventions: {
        // This option sets where we should place non-css and non-js assets in.
        // By default, we set this to "/assets/static". Files in this directory
        // will be copied to `paths.public`, which is set below to "../public".
        assets: /^(static)/,
        ignored: /elm-stuff/
    },
    // paths configuration
    paths: {
        // Dependencies and current project directories to watch
        watched: ["static", "js", "css", "elm"],
        // Where to compile files to
        public: "../public"
    },
    plugins: {
        babel: {
            ignore: [/main.js$/]
        },
        elmBrunch: {
            elmFolder: "elm",
            mainModules: ["Main.elm"],
            makeParameters: ["--warn","--debug"],
            outputFolder: "../js"
        },
        elmCss: {
            projectDir: "elm",
            sourcePath: "Stylesheets.elm",
            pattern: "Style.elm",
            outputDir: "../css"
        },
        cssnano: {
            preset: [
                'default',
                {discardComments: {removeAll: true}}
            ]
        }
    },
    modules: {
        autoRequire: {
            "js/oration.js": ["js/oration"],
            "css/oration.css": ["css/oration"]
        }
    },
    overrides: {
        production: {
            plugins: {
                elmBrunch: {
                    makeParameters: ["--warn"]
                }
            }
        }
    }
};
