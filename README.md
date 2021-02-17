CodeIs.land
===========

Source code for my blog, <https://codeis.land>.

Posts are my own, but go ahead and copy the code for your thing!

[build.sh](build.sh) will install dependencies,
build the site with stack, and serve it at <http://localhost:8000>.
You need to kill and re-run the script to recompile Haskell code,
but everything else updates live as you edit the files.
If you have type errors it will fall back to GHCi.

[publish.sh](publish.sh) will update the static files on the master branch
and push them for use with [Github pages](https://pages.github.com/).
