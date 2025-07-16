---
title: Introducing BigTrees!
tags: bigtrees, github, haskell, python, backups, data-structures, hashes, my-projects
reminder: bigtrees.png
...

[fdupes]: https://github.com/adrianlopezroche/fdupes
[bigtrees]: https://jefdaj.github.io/bigtrees
[linux]: https://github.com/torvalds/linux
[test-files]: https://github.com/Josef-Friedrich/test-files
[script]: ./fetch-test-files.py

I've been working on [a Haskell program][bigtrees] to dedup large collections
of files efficiently. It's still under heavy development, but I think it's at
the point now where it could be useful for a few intrepid testers/power users.

*Most people should default to using an established tool like
[`fdupes`][fdupes] for now.* Then again, if you're reading this you may be an
exception... consider trying [`bigtrees`][bigtrees] if you like/need some of
the features I'm working on, or have an idea about how it could be made to fit
your workflow better than the established tools!

I'll go into more detail on all the cool things you can do with each of these
commands and others "soon"; for now here are 3 short examples.

# Test data

You can already try `bigtrees` on your own data, of course! But maybe you're a
little more careful than that?  If so, use [this Python script][script]. It'll
download the [Linux kernel source code][linux] and [a nice git repo with some
example pictures, music etc][test-files]. Then it'll duplicate them a few times
to get ~1 million test files taking up 18G total.

```.bash
$ export TMPDIR=/tmp
$ time ./fetch-test-files.py
downloading '/tmp/test-files/josef-friedrichj.zip'... ok
unzipping '/tmp/test-files/josef-friedrichj.zip'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe1'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe2'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe3'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe4'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe5'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe6'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe7'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe8'... ok
copying '/tmp/test-files/josef-friedrichj' -> '/tmp/test-files/josef-friedrichj-dupe9'... ok
downloading '/tmp/test-files/linux-source-code.zip'... ok
unzipping '/tmp/test-files/linux-source-code.zip'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe1'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe2'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe3'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe4'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe5'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe6'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe7'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe8'... ok
copying '/tmp/test-files/linux-source-code' -> '/tmp/test-files/linux-source-code-dupe9'... ok

real    3m11.745s
user    0m23.659s
sys     0m22.355s
```

```.bash
$ find test-files | wc -l
957363

$ du -h test-files | tail -n1
18G     test-files

$ tree -L 1 test-files
test-files
├── josef-friedrichj
├── josef-friedrichj-dupe1
├── josef-friedrichj-dupe2
├── josef-friedrichj-dupe3
├── josef-friedrichj-dupe4
├── josef-friedrichj-dupe5
├── josef-friedrichj-dupe6
├── josef-friedrichj-dupe7
├── josef-friedrichj-dupe8
├── josef-friedrichj-dupe9
├── josef-friedrichj.zip
├── linux-source-code
├── linux-source-code-dupe1
├── linux-source-code-dupe2
├── linux-source-code-dupe3
├── linux-source-code-dupe4
├── linux-source-code-dupe5
├── linux-source-code-dupe6
├── linux-source-code-dupe7
├── linux-source-code-dupe8
├── linux-source-code-dupe9
└── linux-source-code.zip

21 directories, 2 files
```

# Minimal dedup command

I'm quite pleased with _how simple_ this looks!
It took a lot of work to get it that way.

```.bash
$ time bigtrees dupes test-files

# This is the default 'suggestions' output format.
# It just suggests what you might delete manually yourself.

# You could save 861228 inodes by deleting all but one of these 10 duplicate directories
test-files/linux-source-code
test-files/linux-source-code-dupe1
test-files/linux-source-code-dupe2
test-files/linux-source-code-dupe3
test-files/linux-source-code-dupe4
test-files/linux-source-code-dupe5
test-files/linux-source-code-dupe6
test-files/linux-source-code-dupe7
test-files/linux-source-code-dupe8
test-files/linux-source-code-dupe9

# You could save 414 inodes by deleting all but one of these 10 duplicate directories
test-files/josef-friedrichj
test-files/josef-friedrichj-dupe1
test-files/josef-friedrichj-dupe2
test-files/josef-friedrichj-dupe3
test-files/josef-friedrichj-dupe4
test-files/josef-friedrichj-dupe5
test-files/josef-friedrichj-dupe6
test-files/josef-friedrichj-dupe7
test-files/josef-friedrichj-dupe8
test-files/josef-friedrichj-dupe9

real    2m42.149s
user    3m29.705s
sys     0m53.310s
```

(I'll go into a few cases where it's not so perfect in future posts)

## Using a `.bigtree` file

These save the directory structure as well as the hash of each file and folder.
They're used when you want to hash files once once and use the results
multiple times. The command above could equivalently be written like so:

```.bash
$ bigtrees hash test-files --output test-files.bigtree
$ bigtrees dupes test-files.bigtree
```

# Minimal diff command

This is meant to take an old and a new collection of files. You might use it to
compare a backup to your current documents, or an older backup to a newer one.
You can also mix and match actual files/dirs with saved `.bigtree` files. Let's
edit `test-files` a little, and see if it can detect the changes.

```.bash
$ rm -r test-files/linux-source-code-dupe7/linux-master/
$ rm -r test-files/linux-source-code-dupe8/linux-master/drivers/pinctrl/realtek/
$ echo "a new file!" > test-files/linux-source-code-dupe8/linux-master/extra.txt

$ time bigtrees diff test-files.bigtree test-files

removed 'linux-source-code-dupe7/linux-master'
added 'linux-source-code-dupe8/linux-master/extra.txt'
removed 'linux-source-code-dupe8/linux-master/drivers/pinctrl/realtek'

real    2m25.713s
user    2m55.189s
sys     0m52.527s
```

You can also compare things that aren't time ordered.
Just keep in mind the changes will flip depending which you put first.

# Minimal find command

Once I started hashing my drives + tarballs and keeping `.bigtree` files
indexing their contents, I realised I could also use them to find particular
files without having the drives on hand. It may not sound like a big upgrade vs
`find`, `locate`, or similar commands, but it's come to be an essential part of
my workflow.

Interactive use is a bit like `find` or `tar --list`.

```.bash
$ bigtrees find test-files.bigtree --search-regex '/old.*\.jpg$'

test-files/josef-friedrichj/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe1/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe2/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe3/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe4/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe5/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe6/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe7/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe8/test-files-master/jpg/old-house.jpg
test-files/josef-friedrichj-dupe9/test-files-master/jpg/old-house.jpg
```
