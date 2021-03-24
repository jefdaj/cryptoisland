CryptoIs.land
=============

Source code for my blog, [Crypto Island][cryptoisland].

Everything is licensed under [CC BY-SA][ccsa4] by default, but I'm probably
open to making exceptions for your commercial thing too as long as you ask
first.

[build.sh][build] will install dependencies, build the site with [Stack][stack],
and serve it at <http://localhost:8000>.
You need to kill and re-run the script to recompile the [Haskell][haskell]
code in [site.hs][sitehs], but everything else updates live as you edit the files.
If you have type errors it will fall back to GHCi.

[publish.sh][publish] will update the static files on the master branch and
push them for use with [Github pages](https://pages.github.com/).

[cryptoisland]: https://cryptois.land
[build]: https://github.com/jefdaj/jefdaj.github.io/blob/master/build.sh
[publish]: https://github.com/jefdaj/jefdaj.github.io/blob/master/publish.sh
[stack]: https://docs.haskellstack.org/en/stable/README
[haskell]: https://www.haskell.org
[sitehs]: https://github.com/jefdaj/jefdaj.github.io/blob/master/src/site.hs
[ccsa4]: https://creativecommons.org/licenses/by-sa/4.0/
