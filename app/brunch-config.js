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
            // Do not use ES6 compiler for debugging
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
            "js/oration.js": ["js/oration"]
        }
    },
    overrides: {
        production: {
            optimize: true,
            sourceMaps: false,
            plugins: {
                autoReload: {
                    enabled: false
                },
                babel: {
                    //Transpile the main file in production
                    ignore: []
                },
                elmBrunch: {
                    makeParameters: ["--warn"]
                }
            }
        }
    }
};
