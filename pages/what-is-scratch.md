---
layout: page
title: What is Scratch?
description: >-
  An introduction to Scratch, the block-based coding tool for children, and
  the storage and permission model behind it.
permalink: /what-is-scratch/
---

<!-- markdownlint-disable-next-line MD034 -->
{% include screenshot.html src="/assets/images/scratch-screenshot.webp" alt="Screenshot of the Scratch online editor showing a project called Satchel, with code blocks controlling a cat sprite that walks, jumps and picks up a satchel, alongside sprite costumes for the cat, satchel, Solid logo and Scratch logo." caption="The Scratch interface at" link_url="https://scratch.mit.edu/" link_text="scratch.mit.edu" %}

[Scratch](https://scratch.mit.edu/){:target="_blank" rel="noopener"} is a visual, block-based programming
language and online community designed for children roughly 8–16, built so
that "programming" means snapping together blocks like *move 10 steps* or
*when green flag clicked* rather than writing text syntax.

<!-- markdownlint-disable MD033 -->
<pre class="blocks">
when green flag clicked
move (10) steps
</pre>
<!-- markdownlint-enable MD033 -->

It was created at the MIT Media Lab's Lifelong Kindergarten Group, led by
[Mitchel Resnick](https://mres.medium.com/10-sparks-that-lit-the-flame-of-scratch-595a27d44334){:target="_blank" rel="noopener"},
with the first prototype in 2003 and a public 1.0 release in January 2007.
Scratch 2.0 (2013) moved the editor into the browser via Flash; Scratch 3.0
(January 2019) was a full rewrite in JavaScript, dropping the Flash
dependency and working on mobile devices. It now has over
[100 million registered users](https://www.media.mit.edu/posts/scratch-100-million-users/){:target="_blank" rel="noopener"}
worldwide.

In October 2019, Scratch was spun out of MIT into the
[Scratch Foundation](https://www.scratchfoundation.org/home){:target="_blank" rel="noopener"}, an independent
nonprofit (itself a rename of the earlier Code-to-Learn Foundation), though
the Lifelong Kindergarten Group at MIT continues to collaborate on Scratch
research. That split matters for how to think about "Scratch" as a system:
it isn't one platform run by one organisation. Scratch 3.0's code is
[open source](https://github.com/scratchfoundation){:target="_blank" rel="noopener"} under AGPLv3, and a
whole ecosystem hosts and modifies it independently. For example:

- [TurboWarp](https://turbowarp.org/){:target="_blank" rel="noopener"}, a popular independent fork with its
  own runtime and storage backend is the best known;
- [ScratchJr](https://www.scratchjr.org/){:target="_blank" rel="noopener"} is a separate, simpler, offline
  app for ages 5–7 with no accounts or servers at all.

In addition, many organisations running coding clubs build their own branded
editors and materials on top of the same open-source base.

## Where Scratch accounts fall short

- **Portability**: A child's "Scratch account" today is really an account on whichever
specific deployment their club, school, or platform happened to run that
session — and each of those accounts, and the projects stored in them, are
separate.

- **Permissions**: The storage and permission model on the flagship `scratch.mit.edu` site is
simple and works well for what it was built for: a project made in the
online editor is **private by default**, visible only to its creator; the
creator can choose to **share** it, which makes it publicly visible and
searchable on the Scratch website (and can later **unshare** it again).

- **Consent**: Creating an account at all requires either being 16 or older, or — if
younger — a parent or guardian's email address to grant consent, a bar the
Scratch Foundation sets higher than the US's COPPA threshold of 13, since
the platform operates worldwide under a patchwork of different national
rules. That consent, though, is a one-time gate at sign-up, not an ongoing
or granular mechanism: once granted, the account and everything shared or
unshared through it is controlled entirely by whoever holds the login.

<!-- markdownlint-disable MD033 -->
<script src="https://cdn.jsdelivr.net/npm/scratchblocks@3.7.1/build/scratchblocks.min.js"></script>
<script>
  scratchblocks.renderMatching('pre.blocks', { style: 'scratch3' });
</script>
<!-- markdownlint-enable MD033 -->
