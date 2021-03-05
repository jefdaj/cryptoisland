CodeIs.land
===========

Source code for my blog, [Code Island](https://codeis.land).

Everything is licensed under [CC BY-SA](https://creativecommons.org/licenses/by-sa/4.0/) by default,
but I'm probably open to making exceptions for your commercial thing too as long as you ask first.

[build.sh](build.sh) will install dependencies,
build the site with [Stack](https://docs.haskellstack.org/en/stable/README/),
and serve it at <http://localhost:8000>.
You need to kill and re-run the script to recompile the [Haskell](https://www.haskell.org/) code
in [site.hs](src/site.hs),
but everything else updates live as you edit the files.
If you have type errors it will fall back to GHCi.

[publish.sh](publish.sh) will update the static files on the master branch
and push them for use with [Github pages](https://pages.github.com/).
