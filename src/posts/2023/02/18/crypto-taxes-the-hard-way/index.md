---
title: Crypto Taxes the Hard Way
tags: hledger, haskell, nix, taxes, accounting, reproducibility, git
updated: 2023-02-25
...

*Disclaimer 1: nothing on this blog is advice about the substance of your taxes!* I have no background in accounting and no idea whether this code will produce valid results. You need to verify everything yourself and then own your own mistakes or hire a tech-savvy [CPA][cpa] (or equivalent in your country) to go over it and fix any problems. That's what I'll be doing.

*Disclaimer 2: this really is the hard way.*
If your taxes are relatively simple, consider trying one of the standard crypto tax subscription services or hiring a human instead. I would guess the break even point is probably around 5-10 different arcane data formats (including banks, exchanges, and wallets). If you're dealing with more than that, it might be worth setting this up.

With that out of the way, I've recently started treating my taxes as a software/data science pipeline! It hasn't been easy, but it has worked better so far than all the easier-sounding ways I've attempted to organize them before. Read on if you think you might be in the same boat...


# Full-fledged `hledger`

[Plain text accounting][pta] is an obvious win in general because you can version control it.
But there are several good tools to choose from and many of their features overlap.
I've gone with [hledger][hl] (so far) mainly so I could follow [this excellent "full-fledged hledger" tutorial][ffhl]. I like the principles in [the README][p1] and [the wiki][p2]. For me, this is the most important part:

> It should be easy to work towards eventual consistency. Large and daunting tasks (like "I will process 10 years of paper mortgage statements" or "I want to import 5 years of paypal payments") should not require one big push and perfect planning to finish them. Instead I should be able to do them bit by little bit, leaving things half-done, and picking them up later with little (mental) effort. Eventually my records would be perfect and consistent.

I might adopt the format advocated by the related [hledger-flow][hlf] project at some point too.

# What to expect from these posts

Today is a "relatively quick start" guide based on [02-getting-data-in][gdi] in [the full-fledged tutorial][ffhl] with mock exchange data rather than a bank account. I suggest starting your own repo right now, working through this first post, working through the rest of that tutorial, and finally coming back here later for crypto-specific addons like:

- importing actual exchange data
- importing historical prices
- importing staking rewards
- handling airdrops, chain splits, rugpulls, and other special cases
- calculating income and capital gains/losses

You'll probably invent some addons of your own too, and I'd love to hear about them!

# Start your repo

<!-- TODO github link to the code once it has a final URL -->

[Here is a tarball of today's code][tarball] to use as a template.
I'll assume you use git for simplicity, but nothing important relies on that.
You can also read through it [on GitHub][gh].

Installing dependencies will probably take at least a couple minutes.
I use [Nix][nix] whenever I expect a project to involve more than one language. To try it that way run [the Nix install script][nis], then open a new terminal and start `nix-shell` inside the repo. Alternatively the full-fledged tutorial includes [a Dockerfile][df] with [a pre-built image][di] you can pull.
 
# Look around
 
## High level tour of the code

Your new repo should look roughly like this (omitting generated files):

~~~{ .txt }
crypto-taxes-the-hard-way/
├── shell.nix (or Dockerfile)
├── 2023.journal
├── all.journal
├── config.journal
├── import
│   └── mockex
│       ├── mockex.rules
│       ├── csv
│       │   └── trades-2023.csv
│       └── csv2journal
├── export.sh
└── export
    └── export.hs
~~~

Manually written hledger journal files go at the top level, input data + code to parse it in `import/`, and the export script + everything it generates in `export/`. The main journal for each tax year depends on the previous year's main + generated journal files. That makes it possible to automatically open and close the books.

Most of the interesting logic is in `export/export.hs`. It's written with [Shake][shake], which is like [Make][make] for [Haskell][haskell]. It parses the journal files for `include` statements and uses those + some hard-coded rules to build a dependency [DAG][dag] and update the relevant files in order when one of the inputs changes. `export.sh` is just a more obvious entry point.

## Follow data from one CSV file

[Here][flow] is an ASCII diagram of data flow through the "full-fledged" system. It's confusing at first but worth learning because it was refined over ~10 years of successful journal maintenance.
For today we'll focus on only the parts needed to answer the question, "What happens when you add or edit a CSV file?"


~~~{ .txt }
import/mockex/csv/* (1)
      +
      |  csv2journal (2)
      v
import/mockex/journal/* (3)
      +
      |
      v
+------------+
|2023.journal| (4)
+------------+
     | |
     | v
     | export/2023-* (5)
     |
     v
+-----------+
|all.journal| (6)
+-----------+
~~~

1. The only data source so far is "MockEx", a made up exchange.
   The trade data starts in `import/mockex/csv/trades-2023.csv`.

~~~{ .txt }
"Transaction ID","Time","Type","Asset","Amount","Fee","Price"
"078werfgsdaf","1/5/2023","buy","BTC",0.01,0.0001,45
"078blk23598s","1/2/2023","buy","BTC",0.01,0.0001,35
~~~

2. `csv2journal` parses the csv according to `import/mockex/mockex.rules`,
   which is written in [the hledger CSV rules format][rules].
   You'll need that because *everyone* seems to make up their own CSV conventions as they go.

3. The generated `import/mockex/journal/trades-2023.journal` in hledger format goes here.
   You'll mainly look at these per-import journal files to debug your CSV rules.

~~~{ .txt }
2023-02-01 (078blk23598s) MockEx buy
    assets:exchanges:mockex       BTC0.0100
    assets:exchanges:mockex          USD-35
    expenses:fees                 BTC0.0001

2023-05-01 (078werfgsdaf) MockEx buy
    assets:exchanges:mockex       BTC0.0100
    assets:exchanges:mockex          USD-45
    expenses:fees                 BTC0.0001
~~~

4. You `include` the per-import journal file in `2023.journal` by hand.
   That tells `export/export.hs` to generate it from the CSV and `hledger` to read it.
   You might also add some transactions here by hand. In this case there's an opening balance.

~~~{ .txt }
;; Settings you want in all your journals
include ./config.journal

;; Opening balances
;; This only needs to be done once for the first year you track
;; After that there are auto-generated opening + closing transactions
2023/01/01 opening balances
  assets:exchanges:mockex    = 100.00 USD
  equity:opening balances

;; Add not-yet-generated files here to tell export.hs to generate them
;; from the corresponding CSV inputs
include ./import/mockex/journal/trades-2023.journal
~~~

6. `export/export.hs` generates financial reports here along with `2023-all.journal`. It looks trivial now (see next section) but once you have dozens of data sources it's is very helpful to see them merged into one linear history.

7. You `include` the journal for each year into `all.journal` by hand.
   It's what you load to look at your finances interactively.

# Try some reports

First, generate all the files:

~~~{ .bash }
[nix-shell]$ ./export.sh
# csv2journal (for ../import/mockex/journal/trades-2023.journal)
# hledger (for 2023-balance-sheet.txt)
# hledger (for 2023-all.journal)
# hledger (for 2023-cash-flow.txt)
# hledger (for 2023-income-expenses.txt)
Build completed in 0.09s
~~~

This will fail if you have any unbalanced transactions according to hledger's version of standard [double-entry accounting][dea] rules.
If you've ever worked with [Haskell][haskell] this will be a similar experience: the compiler complains over and over until every little thing is fixed in your CSV rules, then suddenly it all works and magically writes a consistent history to `2023-all.journal`. Cool, right?

~~~{ .txt }
2023-01-01 opening balances
    assets:exchanges:mockex                 = 100.00 USD 
    equity:opening balances

2023-02-01 (078blk23598s) MockEx buy 
    assets:exchanges:mockex      0.0100 BTC 
    assets:exchanges:mockex       -35.0 USD 
    expenses:fees                0.0001 BTC 

2023-05-01 (078werfgsdaf) MockEx buy 
    assets:exchanges:mockex      0.0100 BTC 
    assets:exchanges:mockex       -45.0 USD 
    expenses:fees                0.0001 BTC 
~~~

The rest of the exported files are standard financial reports. For example a balance sheet:

~~~{ .txt }
Balance Sheet 2023-05-01

                         ||            2023-05-01 
=========================++=======================
 Assets                  ||    
-------------------------++-----------------------
 assets:exchanges:mockex || 0.0200 BTC, 20.00 USD 
-------------------------++-----------------------
                         || 0.0200 BTC, 20.00 USD 
=========================++=======================
 Liabilities             ||    
-------------------------++-----------------------
-------------------------++-----------------------
                         ||    
=========================++=======================
 Net:                    || 0.0200 BTC, 20.00 USD 
~~~

You should version control all of them so you can `diff` them later!
One of the main benefits of this system is being able to refactor aggressively and see what changed.
Try messing up the sign of a number or the name of a field in `mockex.rules` and re-running it.
You should either get an Hledger error about improper transactions or it will succeed and you can `git diff` your final reports.
One way to get a good diff would be to change the name of the `assets:exchanges:mockex` account everywhere.

Finally, play around with some interactive `hledger` commands:

~~~{ .bash }
[nix-shell]$ hledger -f all.journal reg cur:USD assets
2023-01-01 opening balances  assets:exchanges:mockex  100.00 USD  100.00 USD
2023-02-01 MockEx buy        assets:exchanges:mockex   -35.0 USD   65.00 USD
2023-05-01 MockEx buy        assets:exchanges:mockex   -45.0 USD   20.00 USD
~~~

~~~{ .bash }
[nix-shell]$ hledger -f all.journal reg cur:BTC
2023-02-01 MockEx buy  assets:exchanges:mockex  0.0100 BTC  0.0100 BTC
                       expenses:fees            0.0001 BTC  0.0101 BTC
2023-05-01 MockEx buy  assets:exchanges:mockex  0.0100 BTC  0.0201 BTC
                       expenses:fees            0.0001 BTC  0.0202 BTC

~~~

~~~{ .bash }
[nix-shell]$ hledger -f all.journal bal assets
          0.0200 BTC
           20.00 USD  assets:exchanges:mockex
--------------------
          0.0200 BTC
           20.00 USD  
~~~

Your finances will end up being too complicated for any one command to give a good overview, but you can do lots of small checks to build confidence that particular things are going well, then codify them as new report files to check for regressions.
Towards eventual consistency!

# Commit to learning it?

If you're still interested at this point, take a break to let things sink in (really!), then work through at least part of the ["full-fledged hledger"][ffhl] series + do whatever other research seems important. Decide whether you would feel comfortable committing a bunch of time and energy to this stuff.

<!-- TODO point to the investments article here -->

Speaking of which, the one major disadvantage to hledger (vs [ledger][ledger] or [beancount][beancount]) as I see it is the lack of built-in capital gains handling. There are hacky ways to work around that---I'll do a post about my solution soon---but it's something to be aware of from the beginning. I decided the tutorial + CSV parsing infrastructure makes it worth using anyway.

The general idea of plain text accounting is sound, so I think it makes sense to commit to learning it but only provisionally use a specific tool. The journal formats are mostly compatible, minus a few edge cases like capital gains lot handling. So just get started! Once you have your data collected + formatted and a good pipeline structure, changing a few of the commands it invokes isn't as big a deal as it probably sounds now.

[df]: https://github.com/adept/full-fledged-hledger/blob/master/Dockerfile
[di]: https://hub.docker.com/r/dastapov/full-fledged-hledger
[ffhl]: https://github.com/adept/full-fledged-hledger
[flow]: https://github.com/adept/full-fledged-hledger/wiki/Getting-full-history-of-the-account#recap
[gdi]: https://github.com/adept/full-fledged-hledger/tree/master/02-getting-data-in
[hl]: https://hledger.org/
[hlf]: https://github.com/apauley/hledger-flow
[nis]: https://nixos.org/download.html
[nix]: https://nixos.org/nix
[p1]: https://github.com/adept/full-fledged-hledger/wiki/Key-principles-and-practices
[p2]: https://github.com/adept/full-fledged-hledger/wiki
[pta]: https://plaintextaccounting.org/
[dag]: https://en.wikipedia.org/wiki/Directed_acyclic_graph
[rules]: https://hledger.org/1.28/hledger.html#csv-format
[ledger]: https://www.ledger-cli.org/
[beancount]: https://github.com/beancount/beancount
[cpa]: https://www.investopedia.com/terms/c/cpa.asp
[shake]: https://shakebuild.com/
[haskell]: https://www.haskell.org/
[make]: https://en.wikipedia.org/wiki/Make_(software)
[tarball]: crypto-taxes-the-hard-way.tar
[dea]: https://www.investopedia.com/terms/d/double-entry.asp
[gh]: https://github.com/jefdaj/cryptoisland/tree/master/src/posts/2023/02/18/crypto-taxes-the-hard-way/crypto-taxes-the-hard-way
