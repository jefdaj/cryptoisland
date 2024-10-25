---
title: "Hack the Kobo Elipsa for offline use"
tags: offline, databases, sql, privacy, book, hack, tutorial
reminder: island-reading.png
...

There's a semi-standard method for getting Kobo devices to work offline by adding a row to their internal SQLite database.
But I tried and failed to apply it to a first gen Elipsa.

I finally got it to work by combining the sqlite3 code from [kobo-offline][ko]
with the idea of adding a second user from [a LinuxQuestions thread][tr].
Perhaps it also works on the rest of the current (Feb 2024) lineup?

In the 8 months since then I haven't tried to do anything online and haven't been prompted to either.
Just want to document it here in case it helps someone.

# Factory Reset

You could probably skip step #2 here and keep your current settings.
But here are the steps that worked for me:

1. Back up your current settings first if you have anything important.
   See the last step at the bottom for an example `tar` command.

3. Factory reset, select "don't have wifi", connect to computer.
Note that this will delete your book index + annotations.

# Edit SQLite DB

Insert new data using sqlite:

~~~{ .bash }
$ nix-shell -p sqlite3
[nix-shell]$ sqlite3 /media/jefdaj/KOBOeReader/.kobo/KoboReader.sqlite 
SQLite version 3.34.1 2021-01-20 14:10:07
Enter ".help" for usage hints.
~~~

~~~{ .sql }
sqlite> INSERT INTO 'user' (UserID, UserKey, UserDisplayName, UserEmail)
sqlite> VALUES (3, '', 'Foo', 'bar@baz.qux');
sqlite> INSERT INTO 'user' (UserID, UserKey, UserDisplayName, UserEmail)
sqlite> VALUES (4, '', 'FooFoo', 'bar@baz.com');
sqlite> .save /media/jefdaj/KOBOeReader/.kobo/KoboReader.sqlite
sqlite> .quit
~~~

Double check that you ended up with two rows like so:

~~~{ .sql }
select * from user;
3||Foo|bar@baz.qux|||0|0|0|||||1||0||||||-1.0|||||0
4||FooFoo|bar@baz.com|||0|0|0|||||1||0||||||-1.0|||||0
~~~

# Turn off wireless features

Under the settings &rarr; accounts menu, you should see `bar@baz.com` signed in.
Disable wifi, bluetooth, automatic sync, & "automatically share data about features".

# Back up settings

This is optional.
I want to be able to factory reset and then restore the freshly hacked DB quickly if needed.

~~~{ .bash }
$ cd /media/jefdaj/KOBOeReader
$ tar -cvf /tmp/2024-01-09_dot-kobo-hack-success.tar. .kobo/
~~~~

# Use it offline

I mount it as a USB drive and copy EPUBs and PDFs to/from the computer.

You can manage books via drag-and-drop or using something like [Calibre][calibre].
If you read a lot of academic papers you can also sync them via [ZotFile][zotfile].
There's probably an equivalent for [Mendeley][mendeley] too.

Finally, I export my notebooks to PDF (individually via the kobo menu) and `rsync --delete` the `Exported Notebooks` folder to the PC as a backup.

[ko]: https://kobo-offline.virgulilla.com/
[tr]: https://www.linuxquestions.org/questions/linux-hardware-18/kobo-touch-cannot-get-past-welcome-to-kobo-4175695159/page2.html
[calibre]: https://calibre-ebook.com/
[zotfile]: https://zotfile.com/
[mendeley]: https://www.mendeley.com/
