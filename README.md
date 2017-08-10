<img src="https://libbum.github.io/oration/logo_wbl.svg" width=300 px />

A Rocket/Elm self hosted commenting system for static sites.

Inspired by [Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
However, the codebase is unmaintained and [security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.

*Oration* aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.

# Development Startup

```bash
$ echo DATABASE_URL=oration.db > .env
$ diesel migration run
$ cd app/elm
$ elm-package install elm-lang/http
$ elm-package install pukkamustard/elm-identicon
$ cd ..
$ brunch build
$ cd ..
$ cargo run
```

for live reloading of `app` files:

```bash
$ cd app
$ npm run watch
```

