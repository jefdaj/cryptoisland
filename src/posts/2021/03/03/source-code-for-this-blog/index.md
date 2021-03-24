---
title: Source code for this blog
tags: blog, github, hakyll
toc: true
updated: 2021-03-23
...

*Update: Migrated from Github Pages to a personal server*

This site is built with [Hakyll][hakyll].
I've had a great experience with that so far!
Here I'll do a quick overview of how I manage it in case you want to try something similar.
Most of it is based on [this tutorial][tutorial],
but I switched to self-hosting on a VPS rather than via Github Pages.

# Branches

[The `master` branch][master] holds the production source code.
I make a new branch like `master-cssfixes` or `master-greatidea` when
starting any task that has a chance of failing, then merge back into `master`
once I know it works. All my draft posts live on one `drafts` branch. When one
is done I check it out onto `master`, then rebase `drafts` from there.

# Posts

Each post is a folder with [an `index.md` like this][index] and possibly some
other files too: drawings, standalone scripts, etc. The post should contain
links and instructions whenever you can do something non-obvious with the other
files. I mainly write in [Pandoc markdown][markdown], but you can use anything
supported by Pandoc. Posting dates are based on the folder structure, and the
rest is pulled from the markdown header. I date draft posts 2099/something,
which pushes them to the top of the recent posts list and reminds me to fill in
the actual posting date later.

# Scripts

To write I checkout the `drafts` branch, rebase from `master` if needed, and run
[build.sh][build]. It builds a local copy of the site, serves it at
<http://localhost:8000>, and auto-updates it as I change things. The tag cloud,
[RSS feed][atom], CSS, and [recent posts list][recent] auto-update along with the post contents.
The only thing that doesn't auto-update is [the Haskell code][sitehs]; if I
edit that I have to kill and re-run the script. One other gotcha is that I
have to disable caching in Chrome and Firefox to make sure I'm not looking at old
versions of the CSS.

I commit the `drafts` often. Then when a post is done I:

* Check it out onto `master`
* Date it properly
* Commit and push `master`, leaving a clean git repo
* Run [publish.sh][publish] to `rsync` it to the server

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

[master]: https://github.com/jefdaj/cryptoisland/tree/master
[posts]: https://github.com/jefdaj/cryptoisland/blob/master/src/posts/
[index]: https://raw.githubusercontent.com/jefdaj/cryptoisland/master/src/posts/2021/03/03/source-code-for-this-blog/index.md
[build]: https://github.com/jefdaj/cryptoisland/blob/master/build.sh
[publish]: https://github.com/jefdaj/cryptoisland/blob/master/publish.sh
[sitehs]: https://github.com/jefdaj/cryptoisland/blob/master/src/site.hs
[tutorial]: https://jaspervdj.be/hakyll/tutorials/github-pages-tutorial.html
[hakyll]: https://jaspervdj.be/hakyll/
[atom]: /atom.xml
[recent]: /recent.html
[markdown]: https://pandoc.org/MANUAL.html#pandocs-markdown
[nopush]: https://stackoverflow.com/a/30471886
