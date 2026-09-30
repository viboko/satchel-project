---
layout: page
title: "Beyond Scratch: a general principle"
description: >-
  Why the argument behind Satchel isn't really about Scratch specifically,
  and what the prototype will produce that other platforms could reuse.
permalink: /beyond-scratch/
---

Scratch is the specific tool that Satchel focusses on, because it has a real user base and
a real integration to build against, not because the argument is really
about Scratch. The same problem — a child's own record of their work living
inside whichever tool produced it, non-portable, with only a crude
permission model around it — applies to any platform that generates a
child's learning data.

## Where else this applies

- **Other coding editors.** Other block-based and text-based coding tools
  (including other tools built on the open-source Scratch code) keep
  projects in their own database, just as Scratch does.
- **A school's or club's own tools.** Bespoke or in-house systems — a
  school's learning platform, a Code Club's own resources — can hold a
  child's work only for as long as the child is enrolled there.
- **Badge and assessment systems.** Records of what a child has achieved,
  rather than made, face the same lock-in: they usually sit in the
  issuer's system rather than with the child.
- **Anything else a child creates or achieves something in.** Art and music
  tools, writing platforms, game-making environments, portfolio apps.

## The principle

The underlying principle the prototype is meant to demonstrate is
architectural, not Scratch-specific: **a child's learning data should be
stored somewhere the child, together with their guardian, has real control
over, with permission over it granted and revoked by them — not somewhere
decided by whichever vendor happened to build the tool that produced it.**
That control is shared and bounded rather than blanket ownership: a child's
Pod stays structurally separate from a parent's, a guardian is a recorded
relationship rather than an assumed one, and a share needs both the child's
and the guardian's agreement. See [Satchel: adding Solid storage to
Scratch](/what-is-satchel/) for how that works in the prototype.

## What Satchel will produce that others can use

Satchel is not a general-purpose "Solid SDK" — that would promise more than
a prototype can responsibly deliver. It will produce three concrete things
another platform could pick up:

- **A reusable core package.** Everything that isn't specific to Scratch —
  where a piece of work lives in a Pod, saving and loading it, share
  requests, decisions, guardian links, and the rule that decides whether a
  share is approved — packaged under an MIT licence. A different tool
  reuses it as-is and writes only its own small adapter: save and load work
  against a Pod instead of its own database.
- **One reference implementation.** The working Scratch integration, built
  on the open-source `scratch-gui`, as a worked example to read, copy or
  adapt — along with the dashboard where sharing decisions are made, and
  the agent that carries them out.
- **A published vocabulary for guardianship and consent.** The data model
  describing guardians, dependents, share requests, decisions and audit
  entries, built on existing vocabularies (DPV, FOAF, ODRL, PROV-O and
  others) with a small new piece for the guardian relationship. Published
  as something another project can import, so that tools which have never
  heard of each other — including a different dashboard or agent — can
  still read the same permissions in the same Pod.

If the Scratch integration works, a resource-level, revocable permission
model backed by a Pod should transfer to any other tool willing to read and
write against a Pod instead of its own database.
