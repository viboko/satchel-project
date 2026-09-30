---
layout: page
title: How this differs from previous attempts
description: >-
  How Satchel's architecture avoids the failure mode that sank earlier
  attempts at centralised student records, like inBloom.
permalink: /how-this-differs/
---

Portable, learner-centred records of a child's work aren't a new idea — the
question is whether the mechanism behind them avoids the failure mode that
has sunk or sidelined previous attempts.

## inBloom: a centralised store parents wouldn't trust

**inBloom** was a US nonprofit, launched in 2013 with roughly $100 million,
mostly from the Bill & Melinda Gates Foundation and the Carnegie
Corporation. It aimed to give teachers a single, centralised store of
student data to personalise instruction. It began with nine participating
states, and was wound down in April 2014, roughly a year after launch.

The fullest account of what happened is Data & Society's 2017 "autopsy,"
[The Legacy of inBloom](https://datasociety.net/research-library/the-legacy-of-inbloom/){:target="_blank" rel="noopener"},
based on interviews with 18 stakeholders. Two articles covering it pick out
different parts of its findings:

- **[Education Week, 2017](https://www.edweek.org/technology/autopsy-of-inbloom-sparks-old-debates-about-sharing-student-data/2017/02){:target="_blank" rel="noopener"}**
  focuses on the report's disagreement over blame. Supporters blamed
  unrealistic ambitions, poor implementation and a misreading of the
  fragmented US school system; parent activists rejected that framing,
  arguing that treating opposition as irrational assumed inBloom was worthy
  of trust in the first place. The fallout included more than 400 state
  bills on student-data privacy.
- **[THE Journal, 2017](https://thejournal.com/articles/2017/02/15/autopsy-for-the-failure-that-was-inbloom.aspx){:target="_blank" rel="noopener"}**
  focuses on the report's other findings: bad timing, launched amid the NSA
  revelations and high-profile breaches; no compelling story about benefits
  for teaching and learning; and a coalition that shrank from nine states to
  three within months.

The accounts disagree about how much was avoidable — inBloom's own
supporters cite poor communication and delivery, its opponents cite a
reasonable refusal to trust — but they agree that the technical design was
not what sank it. What parents and states rejected was a single
organisation holding sensitive data on children at scale, and asking them
to trust its safeguards. Better communication might have delayed that
reaction, but it doesn't change the structure that provoked it.

## Satchel's structural difference

Satchel's structural difference is that **Solid never puts the data in one
organisation's central database in the first place.** Each child's data
lives in their own Pod, and sharing is a resource-level, revocable grant
written into that Pod, not a policy promise made by an intermediary. That's
a difference in where the data physically lives and who can grant access to
it, which is what can make it survive a vendor changing hands, going out
of business, or being asked to share data in a way a family didn't expect —
in a way a centralised store structurally can't.

The control isn't blanket "family" ownership, though. The child and their
guardian are separate parties, a guardian is a recorded relationship rather
than something inferred from being a parent, and a share only takes effect
when both agree, with either able to revoke it. The full model is in
[Satchel: adding Solid storage to Scratch](/what-is-satchel/).

Decentralised storage removes the single-point-of-trust failure mode, but
it doesn't by itself solve, for example, who holds a young child's Pod
credentials or what happens if a family loses them.
