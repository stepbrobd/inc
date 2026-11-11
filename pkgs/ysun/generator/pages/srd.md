---
title: Static race detection
description: Naive data race detector for Go based on stateful AST traversal with pre-defined structural operational semantic rules
created: 2023-05-11
updated: 2026-02-13
metas:
  go-import: ysun.co/srd git https://github.com/stepbrobd/srd.git
  go-source: ysun.co/srd https://github.com/stepbrobd/srd https://github.com/stepbrobd/srd/tree/master{/dir} https://github.com/stepbrobd/srd/blob/master{/dir}/{file}#L{line}
---

## Problem

A common misuse of Go's channels and goroutines that can lead to data races
involves the incorrect assumption that sending to or receiving from a channel
implies synchronization between goroutines.

Example of a data race caused by unsynchronized access to shared data across
multiple goroutines:

```go
package main

import "fmt"

func main() {
    var data int

    go func() {
        data++
    }()

    go func() {
        fmt.Println(data)
    }()
}
```

Corrected version of above example using channels to synchronize goroutines and
prevent data races:

```go
package main

import "fmt"

func main() {
    var data int
    done := make(chan bool)

    go func() {
        data++
        done <- true
    }()

    go func() {
        <-done
        fmt.Println(data)
    }()
}
```

In the above examples, two goroutines are spawned. One increments the global
data variable, and the other attempts to print the data variable. However, there
is no guarantee of the order in which these goroutines will be scheduled to run.
As a result, the printed value could be 0 (if the printing happens before the
increment) or 1 (if the printing happens after the increment). This is a classic
example of a data race. The idiomatic Go solution to this problem is to use
channels to synchronize the goroutines. The sending goroutine can send a signal
over the channel when it has finished its operation, and the receiving goroutine
can wait for this signal before it begins its operation. In the corrected code,
a `done` channel is used to synchronize the two goroutines. The incrementing
goroutine sends `true` over `done` when it has finished its operation. The
printing goroutine waits to receive from the `done` before it begins its
operation, ensuring that it only prints `data` after the incrementing goroutine
has finished.

This use of channels to synchronize goroutines is in line with the Go philosophy
of sharing memory by communicating, rather than communicating by sharing memory.
Instead of both goroutines accessing the shared data variable with no
synchronization (which leads to a data race), the goroutines use a channel to
communicate and synchronize their operations, ensuring that the data variable is
only accessed when it is safe to do so.

## Structural Operational Semantics

To formalize the problem and above mentioned fix, we can represent the program
as a set of rules that describe how the state of the system changes based on
certain conditions. In this case, we want to model the behavior of goroutines
and channels in Go, particularly focusing on the synchronization of goroutines
via channels.

The configuration of our program can be defined as a tuple _(G, M, C)_ where:

- _G_ is the set of goroutines,
- _M_ is the memory, represented as a mapping from variables to values,
- _C_ is the set of channels, represented as a mapping from channel identifiers
  to lists of values.

We can use the following SOS rules:

**Goroutine Creation**

$$\frac{}{(G, M, C) \xrightarrow{\texttt{go f()}} (G \cup \{\texttt{f()}\}, M, C)}$$

**Memory Modification**

$$\frac{\texttt{f()}\ \text{is}\ \texttt{data++}}{(G, M, C) \xrightarrow{\texttt{go f()}} (G - \{\texttt{f()}\}, M[\texttt{data} \rightarrow M(\texttt{data}) + 1], C)}$$

**Channel Send**

$$\frac{\texttt{f()}\ \text{is}\ \texttt{done <- true}}{(G, M, C) \xrightarrow{\texttt{go f()}} (G - \{\texttt{f()}\}, M, C[\texttt{done} \rightarrow C(\texttt{done}) \cup \{\texttt{true}\}])}$$

**Channel Receive**

$$\frac{\texttt{f()}\ \text{is}\ \texttt{<-done}}{(G, M, C) \xrightarrow{\texttt{go f()}} (G - \{\texttt{f()}\}, M, C[\texttt{done} \rightarrow C(\texttt{done}) - \{\texttt{true}\}])}$$

**Print**

$$\frac{\texttt{f()}\ \text{is}\ \texttt{fmt.Println(data)}}{(G, M, C) \xrightarrow{\texttt{go f()}} (G \cup \{\texttt{f()}\}, M, C)}$$

Please note that this is a simplified model. In a more comprehensive model, you
would want to handle cases like sending to a full channel, receiving from an
empty channel, and more complicated goroutine interactions. In addition, you
might want to include a scheduler in the state to control the order in which
goroutines are run, and to handle the non-deterministic scheduling of goroutines
by the Go runtime.

## Static Analysis

Accompanying this report, there is a demo Go program that uses simple static
analysis technique to detect potential data races. The analysis is performed
based on the traversal of the Abstract Syntax Tree (AST) of given Go code
specified by a command line argument.

The main structures are:

- The State struct, which models the state of a Go program in terms of active
  goroutines, memory locations that have been written to, and channels that have
  been used for sending and receiving data.
- The Visitor struct, which is used for traversing the AST. It updates the State
  according to the different types of nodes encountered in the AST.

The analysis checks for potential data races by looking for memory locations
that have been written to more than once, which could indicate a data race if
these write operations are not properly synchronized.

However, it's important to note that this analysis is a simple and somewhat
naive approach to data race detection. It has several limitations and
assumptions that may lead to inaccuracies:

- All function calls are assumed to be print statements, which simplifies the
  analysis but is not accurate for general Go code.
- The analysis assumes that every increment/decrement operation indicates a
  write to a shared memory location. However, in real Go programs, many of these
  operations might be operating on local variables that are not shared between
  goroutines.
- The analysis doesn't account for the synchronization provided by Go's
  concurrency primitives like locks or the proper use of channels.

To make this program a reliable tool for data race detection, it would need to
be significantly expanded and refined to accurately model the behavior of Go
programs, including the semantics of Go's concurrency primitives and the scope
and lifetime of variables. The goroutine creation and memory modification rules
would need to be more precisely defined and applied only in appropriate
contexts. In its current form, it serves as a basic demonstration of how AST
traversal can be used for static analysis.

## Installation & Usage

Note that this is just a naive proof-of-concept tool and is trivial to bypass by
using more complex patterns (well, being honest, I think any form other than the
ones specified in the examples can bypass all the checks).

With Go installed, you can install the tool by running the following command:

```shell
go get -u ysun.co/srd
```

To use as library, import the package:

```go
import "ysun.co/srd"
```

If you have a working Nix installation:

```shell
nix run nixpkgs#go -- run -race cmd/srd/main.go -- examples/example_*.go
```

Source code: <https://github.com/stepbrobd/srd>
