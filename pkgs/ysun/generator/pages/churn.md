---
title: Churn
description: Churn, baby, churn!
created: 2024-03-30
updated: 2026-09-06
hidden: true
metas:
  go-import: ysun.co/churn git https://github.com/stepbrobd/churn.git
  go-source: ysun.co/churn https://github.com/stepbrobd/churn https://github.com/stepbrobd/churn/tree/master{/dir} https://github.com/stepbrobd/churn/blob/master{/dir}/{file}#L{line}
---

> This is a very old project of mine that is no longer maintained. This page is
> kept for archival purposes only. No one should ever use it in its current
> state as is without extensive audit and modifications.

## Motivation

Credit card churing (or simply churing) is a term commonly used in multiple
well-known communities (e.g. [r/churing](https://www.reddit.com/r/churning) on
Reddit, [The Points Guy](https://thepointsguy.com),
[Doctor of Credit](https://www.doctorofcredit.com), etc.). Simply put, it refers
to the process of consumers applying for credit cards to take advantage of
sign-up bonuses (or other promotions) to maximize the amount of "cash back" or
"points" they can get. Many fears that churing is illegal or unethical. However,
it is not (well, if you follow the terms and conditions). It is simply a way to
"earn back" some of the money that consumers have spent.

Churning is fun, but complex. It requires a lot of planning and tracking. For
example, consumers need to keep track of the credit cards they have applied for,
the annual fees they need to pay, the minimum spending they need to meet to get
the sign-up bonuses, etc. Thus, to simplify the bookkeeping, this project aims
to develop a command-line tool to help consumers track their credit card churing
activities (there is no offical survey, but personally, I believe a good
percentage of churing enthusiasts are tech-savvy and would love to use a
command-line tool).

The motivation behind this project is my personal interest in credit card
churing and have been annoyed by the lack of a good tool to help me keep track
of my churing activities. I hope this tool can help me and other churing
enthusiasts replace to Google Sheets or other manual entry methods.

## Installation & Usage

With Go installed, you can install the tool by running the following command:

```shell
go get -u ysun.co/churn
```

To use as library, import the package:

```go
import "ysun.co/churn"
```

If you have a working Nix installation:

```shell
nix run github.com/stepbrobd/churn
```

Source code: <https://github.com/stepbrobd/churn>
