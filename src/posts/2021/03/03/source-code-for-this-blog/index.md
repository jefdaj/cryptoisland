---
title: Source code for this blog
tags: blog, github, hakyll, haskell, html, css, javascript, git, browsers
updated: 2024-10-25
reminder: sand-castle.png
...

This site is built with [Hakyll][hakyll].
I've had a great experience with that so far!
It uses Haskell to generate a static HTML + CSS site, and doesn't require the user to enable JS.
_Update: 3.5 years later, I would do it the same way again if starting over._

Here I'll do a quick overview of how I manage it in case you want to try something similar.
Most of it is based on [this tutorial][tutorial],
but I switched to self-hosting on a VPS rather than via Github Pages.

# Branches

[The `master` branch][master] holds the production source code.
I make a new branch like `cssfixes` or `newidea` when
starting any task that has a chance of failing, then merge back into `master`
once I know it works. I tried a branch per post, but it quickly became unwieldy.
Now all my draft posts live on one `drafts` branch.

# Draft posts

Each post is a folder with [an `index.md` like this][index] and possibly some
other files too: drawings, standalone scripts, etc. The post should contain
links and instructions whenever you can do something non-obvious with the other
files. I mainly write in [Pandoc markdown][markdown], but you can use anything
supported by Pandoc. Posting dates are based on the folder structure, and the
rest is pulled from the markdown header.

I date draft posts `2099/XX/XX`, which pushes them to the top of the recent
posts list and reminds me to fill in the actual posting date later.
I tend to group them by topic too. For example `2099/01/*` might be about
Haskell and `2099/02/*` about prediction markets.


# Continuous build

To write I checkout the `drafts` branch, `rebase -Xtheirs master` if needed, and run
[build.sh][build]. It builds a local copy of the site, serves it at
<http://localhost:8000>, and auto-updates it as I change things. The tag cloud,
[RSS feed][atom], CSS, and [recent posts list][recent] auto-update along with the post contents.
The only thing that doesn't auto-update is [the Haskell code][sitehs]; if I
edit that I have to kill and re-run the script.

# Browsers

I use the [Tab Reloader plugin][plugin] in both FireFox and Chrome, and set it to reload every 10 seconds while writing.

One other gotcha is that I have to disable caching (Developer Tools &rarr; Network &rarr; "Disable cache") in each browser to make sure I'm not looking at old
versions of the CSS. Chrome sometimes does it anyway and needs to have its history cleared.

# Publishing a post

I save the drafts often, naming commits by the post(s) they edit.
Then when a post is done I:

* `git mv` the `2099/XX/XX` date folder to the current date
* Check it out onto `master`
* Commit and push `master`, leaving a clean git repo
* Run [build.sh][build] again, which creates the `.site` folder
* Run [publish.sh][publish] in another terminal to `rsync` it to the server
* Checkout `drafts` again and `git rebase -Xtheirs master`

# Guardrails

To ensure that I don't accidentally publish drafts before they're ready,
I have a pre-push hook as suggested [here][nopush]:

~~~{ .bash }
# .git/hooks/pre-push
url="$2"
if [[ `grep 'draft'`&& "$url" =~ github ]]; then
  echo "Don't push the drafts branch to github! Aborting."
  exit 1
fi
~~~

I also remove them in `publish.sh` and `.gitignore`:

~~~{ .bash }
# publish.sh
# Just in case, remove accidentally-added draft posts before publishing
rm -rf .site/posts/2099
~~~

~~~{ .bash }
# .gitignore
# Ignore draft posts
# (This should be commented out of .gitinore on the drafts branch)
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
[plugin]: https://webextension.org/listing/tab-reloader.html
