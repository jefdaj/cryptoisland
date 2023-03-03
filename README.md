CryptoIsland
============

Source code for my blog, [Crypto Island][cryptoisland].

Everything is licensed under [CC BY-SA][ccsa4] by default, but I'm probably
open to making exceptions for your commercial thing too as long as you ask
first.

`nix-shell --run ./build.sh` will install dependencies, build the site,
and serve it at <http://localhost:8000>.
You need to kill and re-run the script to recompile the [Haskell][haskell]
code in [site.hs][sitehs], but everything else updates live as you edit the files.
If you have type errors it will fall back to GHCi.

Once you have the right HTML built locally,
`nix-shell --run ./publish.sh` will push it to the server.

[cryptoisland]: https://cryptoisland.blog
[haskell]: https://www.haskell.org
[sitehs]: https://github.com/jefdaj/jefdaj.github.io/blob/master/src/site.hs
[ccsa4]: https://creativecommons.org/licenses/by-sa/4.0/
