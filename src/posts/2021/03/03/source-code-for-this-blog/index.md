---
title: Source code for this blog
tags: blog, github, hakyll
toc: true
...

This site is built with [Hakyll][hakyll] and hosted on [Github][github].
I've had a great experience with that so far!
Here I'll do a quick overview of how I manage it in case you want to try something similar.
Most of it is based on [this tutorial][tutorial].

# Branches

[The `master` branch][master] holds the unreadable HTML that Github is actually
serving. Start on [the `develop` branch][develop] instead for the source code.
I make a new branch like `develop-cssfixes` or `develop-greatidea` when
starting any task that has a chance of failing, then merge back into `develop`
once I know it works. All my draft posts live on one `drafts` branch. When one
is done I check it out onto `develop`, then rebase `drafts` from there.

# Posts

Each post is a folder with [an `index.md` like this][index] and possibly some
other files too: drawings, standalone scripts, etc. The post itself should
contain links and instructions whenever you can do something non-obvious with
them. I mainly write in [Pandoc markdown][markdown], but you can use anything
supported by Pandoc. Posting dates are based on the folder structure, and the
rest is pulled from the markdown header. I date draft posts 2099/something,
which pushes them to the top of the recent posts list and reminds me to fill in
the right date later.

# Scripts

To write I checkout out one of the `develop` branches and run
[build.sh][build]. It builds a local copy of the site, serves it at
<http://localhost:8000>, and auto-updates it as I change things. The tag cloud,
[RSS feed][atom], CSS, and [recent posts list][recent] auto-update along with the post contents.
The only thing that doesn't auto-update is [the Haskell code][sitehs]; if I
edit that I have to kill and re-run the script. One other gotcha is that you
should disable caching in your browser to make sure you aren't looking at old
versions of the CSS/JS.

When I'm ready I commit and push the `develop` branch, then run [publish.sh][publish] to do the rest.
It does one more clean build, checks out `master`, overwrites it with the current code,
and pushes that to Github. I was wary of the magic at first, but it seems relatively safe.

To ensure that I don't accidentally publish draft posts I have a pre-push hook
as suggested [here][nopush]:

~~~{ .bash }
# .git/hooks/pre-push
if [[ `grep 'draft'` ]]; then 
  echo "You really don't want to push the drafts branch. Aborting."
  exit 1
fi
~~~

I also remove them in `publish.sh` and `.gitignore`:

~~~{ .bash }
# publish.sh
# Just in case, remove accidentally-added draft posts
rm -rf posts/2099
~~~

~~~{ .bash }
# .gitignore
src/posts/2099
~~~

[github]: https://github.com/jefdaj/jefdaj.github.io
[master]: https://github.com/jefdaj/jefdaj.github.io/tree/master
[develop]: https://github.com/jefdaj/jefdaj.github.io/tree/develop
[posts]: https://github.com/jefdaj/jefdaj.github.io/blob/develop/src/posts/
[index]: https://raw.githubusercontent.com/jefdaj/jefdaj.github.io/develop/src/posts/2021/03/03/source-code-for-this-blog/index.md
[build]: https://github.com/jefdaj/jefdaj.github.io/blob/develop/build.sh
[publish]: https://github.com/jefdaj/jefdaj.github.io/blob/develop/publish.sh
[sitehs]: https://github.com/jefdaj/jefdaj.github.io/blob/develop/src/site.hs
[tutorial]: https://jaspervdj.be/hakyll/tutorials/github-pages-tutorial.html
[hakyll]: https://jaspervdj.be/hakyll/
[atom]: /atom.xml
[recent]: /recent.html
[markdown]: https://pandoc.org/MANUAL.html#pandocs-markdown
[nopush]: https://stackoverflow.com/a/30471886
