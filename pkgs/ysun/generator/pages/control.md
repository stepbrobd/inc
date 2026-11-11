---
title: Under control
description: Under Control zine for iPPL extended version
created: 2024-12-06
updated: 2026-02-12
---

I took [CS 7400](https://ccs.neu.edu/~cmartens/Courses/7400-f24/index.html)
(Intensive Principles of Programming Languages a.k.a iPPL) this semester under
Prof. Martens. This blog post builds upon the ideas introduced in
[my original 8-page-long Zine](/assets/static/doc/ctrl.pdf) on control stacks
(well, tbh I chose Control Stacks because it's the most intuitive topic covered
in this class).

IMO control stacks help capture the evaluation states and "rest of the
computation" as programs run. While in the Zine example, they track function
calls and returns, conceptually, they stand at the intersection between type
systems and operational semantics. Instead of leaving the evaluation orderings
implicit, control stacks solidifies the sequences and structures of
computations.

## Typing rules

In my original Zine, I focused on the intuitive idea of control stacks without
diving into the nitty-gritty details of how we know a program is "well-typed" or
what "well-typed" even means. But as soon as you start working with formal
semantics, you realize the typing rules you choose play a huge role in what
kinds of computations your stack machines can handle (well also congruence
rules, but we'll cover that later).

The Simply Typed Lambda Calculus (STLC) rules I used were inherited from my
class (fairly standard) but lots of symbols (I got scared in the first couple
lectures). They are not exactly beginner-friendly if you're seeing it for the
first time. STLC defines a set of rules that dictate how terms like function
definitions (`lambda x. e`), function applications (`f e`), sums (`A + B`),
products (`A X B`), and so forth should be typed so that we can guarantee the
expressions we write based on those rules are well-formed.

As an oversimplification, typing rules define what syntax is allowed in your
language, establish the foundation of its evaluation model (operational
semantics), and ensure that if evaluation takes place, it won't get stuck in
some meaningless or undefined state. In other words, typing rules aren't just
about decorating your syntax with types, they carve out which programs are even
considered valid, so that if you run them on a stack-based interpreter, you know
they'll behave according to the rules and produce results (or at least stop
cleanly) without halting in some bizarre, unexpected configuration. These rules
support the theoretical guarantees that make control stacks not only
conceptually neat but also practically reliable [^1].

[^1]: I think this is somehow very similar to the ideas introduced in
    [Theorems for Free!](https://people.mpi-sws.org/~dreyer/tor/papers/wadler.pdf)

Something I didn't get right away when I first saw them (if you want to take a
look at the full typing rules, go to the course website and check the last
couple pages of assignment 2):

| Construct                             | Explanation                                                                                                                                                                                                                                     |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `in_l(e)` and `in_r(e)`               | You use these on sum types. It's like having two labeled boxes and pick a value in one of them                                                                                                                                                  |
| `case(e, x.e1, y.e2)`                 | It's also used on sum types. It's like opening a box that could contain either a left or a right. Usually used with `in_l(e)` or `in_r(e)`, and `e` binds to the variable on whichever branch you picked                                        |
| `pair(e1, e2)` and `split(e, x.y.e')` | `pair` and `split` deal with product types. Think of `pair` as bundling two items into a single box, and `split` as the process of opening that box and working with each item individually, and the two item binds to `x` and `y` respectively |

Typing rules are more intricate than what you've just read. To _really_
understand them, you'd need to work through some actual typing derivations, see
how the pieces fit together. Doing some casual reading like this won't cut it.

## Operational semantics

Once you have well-typed programs, how do you actually _run_ them? That's where
_stepping rules_ or _computation rules_ come into play. They define how
evaluation steps propagate inside nested expressions (or simply expressions that
is not a value yet). For example, if you have `f e`, but `f` isn't a value yet,
you might need to step `f` first before applying it to `e`.

When defining those rules, the single step operator `|->` is used to connect two
expressions like `e |-> e'`, where the type if `e` is congruent to the type of
`e'`. Here, `e'` is usually "closer" to a value than `e`. Each step ensures that
the computation moves forward, peeling away layers of the expression and turning
it into something "simpler" (or towards something that's more like a value),
until eventually you reach a value.

For instance, consider the `pair` and `split` constructs from before. If you
have `split(pair(v1,v2), x.y.e)`, the computation rule says you can replace that
whole thing with `[v1/x][v2/y]e`, in other words, you open the pair, replace its
contents (`x` with `v1` and `y` with `v2`), within the expression `e`.

Congruence rules are like extensions of computation rules. Think of them as
roadmaps for reducing more complex expressions. If you have an expression like
`f e`, then `f e |-> f' e` given `f |-> f'` (check the full STCL rule sheet in
assignment 2).

## Control stacks

I also skipped the syntax of control stacks in the Zine. In the stack-based
operational semantics, we model the ongoing computation as a _control stack_ or
a stack of _frames_ indicating what's left to do.

In the syntax, we have:

- A stack `k` can be empty (`epsilon`) or can have frames appended (separated by
  `;`)

- Each frame `f` captures a pending operation that awaits a value in a specific
  position (a "hole").

For example, a frame might represent waiting for the argument of a function
application to become a value, or for the inner expression of a `case` to
resolve, or for one branch of a `pair` to finish evaluating. In STLC with sums
and products, you have frames like `(HOLE e)`, `(f HOLE)`, `in_l(HOLE)`,
`in_r(HOLE)`, or `case(HOLE, x.x, y.y)` to show exactly where the next step of
evaluation should happen (these examples looks awfully familiar huh? hint: page
4).

## Back to Zine

- **Typing rules**\
  They ensure that every program you evaluate is well-formed and capable of
  taking valid next steps.

- **Operational semantics**\
  They describe _how_ you take those next steps. Stepping rules (computation
  rules) detail the transformations you apply at each step. Congruence rules
  tell you where to focus these transformations.

- **Control stacks:**\
  Explicitly tracking stepping contexts in frames. The stack machine model shows
  that every well-typed term eventually reduces to a value, or halts in a
  well-defined way [^2] if that's the language's design.

  - **Soundness** Guarantees that well-typed programs don't get stuck.

  - **Completeness** Ensures that from a well-typed starting state, the
    reduction process can lead you to a final value or an exception
    deterministically.

[^2]: See exceptions in iPPL lecture note 16 or PFPL chapter 28
