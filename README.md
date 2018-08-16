<img src="https://libbum.github.io/oration/logo_wbl.svg" width=400 px />

A Rocket/Elm self hosted commenting system for static sites.

Inspired by [Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
However, the codebase is unmaintained and [security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.

*Oration* aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.

---

Oration is currently in an early stage of development, but [v0.1.1](https://github.com/Libbum/oration/releases/tag/v0.1.1) is usable now with minimal setup and a good deal of front facing features.
Administration, porting from other commenting systems and a number of additional features are [planned](https://github.com/Libbum/oration/milestones) with a roadmap targeting a complete public release at v0.3.

Contributions are welcome, please see our [guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

# Get it running now

A static binary for the backend that runs on any Linux machine can be found in the [release tarball](https://github.com/Libbum/oration/releases/download/v0.1/oration-v0.1.tar.gz), along with a configuration file and minified `oration.{js,css}` files for you to put in your blog files.

A staging virtual machine using [Vagrant](https://www.vagrantup.com/) and [Ansible](https://www.ansible.com/) is available if you wish to build a test machine direct from the source, although this will require a few more development tools to be installed on your system (like docker for instance).
Please read the comments in [`staging/prepare.yml`](staging/prepare.yml) to setup the standalone build system.
However, this staging setup shows you exactly how to put oration behind an [Nginx proxy](staging/config/nginx.vhost.conf) with hardened security headers, once you have it [running as a service](staging/config/oration.service).

Before running the service, make sure an `.env` file that points to the location of an sqlite database initialised with [these commands](migrations/20170719094701_create_oration/up.sql), and the [configuration file](oration.yaml) with details specific for your machine both exist in the directory oration is located in.

On the front end, it's simply a manner of uploading the css and js files to your public directory, and editing your blog posts to point to these assets.
An example of this can be seen [here](app/static/post-1.html).

More complete documentation is on the way.

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

Until such time as I fix the build system, you'll also need to do some finicky stuff to get the style sheets building correctly.

From the `app` directory:
1. `mkdir css`
2. `npm run watch`
3. Edit `elm/Stylesheets.elm` and save it.

# Documentation

Documentation of current backend methods can be viewed [here](https://libbum.github.io/oration/oration/index.html).

# Options

Code highlighting is done with [prism.js](http://prismjs.com/).
The default syntax pack and a few extra markups are obtained via a CDN here, although you may wish to modify the allowable languages used on your blog.
Replace the default pack with one customised from [here](http://prismjs.com/download.html) to achive this.
The CDN isn't a bad idea however, and pulling multiple files the example here is all done over http v2, so it's pretty fast.

In the same manner, you may change the theme of the syntax highlighting by choosing [another theme](https://github.com/PrismJS/prism/tree/gh-pages/themes).
Oration uses the default in the example file.

These changes should be in your own html files, an example can be seen in the bundled [index.html](app/static/index.html) header.


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FLibbum%2Foration.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2FLibbum%2Foration?ref=badge_shield)

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FLibbum%2Foration.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FLibbum%2Foration?ref=badge_large)
