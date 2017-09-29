<img src="https://libbum.github.io/oration/logo_wbl.svg" width=400 px />

A Rocket/Elm self hosted commenting system for static sites.

Inspired by [Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
However, the codebase is unmaintained and [security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.

*Oration* aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.

---

Currently, Oration is in an alpha stage of release with no particular estimate for hitting v0.1.

Contributions are welcome, please see our [guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

# Development Startup

```bash
$ echo DATABASE_URL=oration.db > .env
$ diesel migration run
$ cd app/elm
$ elm-package install
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

# Documentation

Documentation of current backend methods can be viewed [here](https://libbum.github.io/oration/oration/index.html).
