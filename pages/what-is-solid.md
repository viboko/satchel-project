---
layout: page
title: What is Solid?
description: >-
  An introduction to Solid, the open web standard for personal data
  storage that Satchel is built on.
permalink: /what-is-solid/
---

![The Solid logo](/assets/images/solid-logo.svg)
{: .logo }

[Solid](https://solidproject.org/){:target="_blank" rel="noopener"} is an open web standard, originated by
[Tim Berners-Lee](https://medium.com/@timberners_lee/one-small-step-for-the-web-87f92217d085){:target="_blank" rel="noopener"}
(the same person who invented the web itself), for a different way of
storing personal data online. It isn't a company, a product, or a single
website you sign up to — it's a protocol, with several independent, mostly
open-source implementations, in roughly the same way "email" is a protocol
that Gmail, Outlook, and a hundred smaller providers all implement rather
than something one company owns.

The problem it's aimed at: almost every app you use — Scratch included —
stores your data on its own servers, in its own account system, under its
own rules. If you stop using the app, or the organisation running it shuts
down, changes its terms, or gets bought, your data usually stays locked
inside it. Solid's proposal is to separate the *app* from the *storage*:
instead of every app holding its own private copy of your data, you keep
your data in a personal online datastore called a **Pod** — short for
"Personal Online Datastore."

![Diagram showing a person's Solid Pod at the centre, with different apps connecting to it to request access to the data inside](/assets/images/solid-diagram.svg)

Think of a Pod as a locker that belongs to you:
you choose which apps get a key to which parts of it and you
can move the locker itself to a different provider (or run your own)
without losing access to what's inside or having to ask every app to
migrate with you.

Two things about Solid matter most for this project:

1. **Decouples data storage from application implementation.** Because Solid is an open
  protocol rather than one vendor's product, a Pod isn't tied to any one
  organisation's continued existence or goodwill. See
  [How this differs from previous attempts](/how-this-differs/).
  
2. **Fine-grained, revocable permission**, not an all-or-nothing switch. A
  Pod owner can grant a specific person or app access to one specific piece
  of data and take that access away again later — instead of a single "shared" or "not shared" toggle that applies to everything or nothing.
