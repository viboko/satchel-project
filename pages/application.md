---
layout: page
title: "Satchel: application to the ODI Solid open call"
description: >-
  Satchel's application to the Open Data Institute's Solid use case open
  call.
permalink: /application/
---

<!-- The form's question labels are bold text, mirroring the original form. -->
<!-- markdownlint-disable MD036 -->

Satchel is a proposal in response to the Open Data Institute's [Solid use case open call](https://theodi.org/news-and-events/blog/solid-open-call/){:target="_blank" rel="noopener"}, which offers in-kind support to non-commercial projects using Solid for social good.

**Project name**
> Satchel (working title)

**What is your organisational type?**

> Individual applicant, not affiliated with an organisation.

**Who will work on the project?**

> Just me (1 person), covering design and full-stack development. I am a software engineer with more than 20 years experience. I recently left my job to focus on projects which are personally interesting to me, so the Solid Open Call came at an ideal time. I am super keen to learn about Solid and promote its adoption.
>
> I run a local Code Club ([gravesend-code-club.viboko.dev](https://gravesend-code-club.viboko.dev/){:target="_blank" rel="noopener"}) and plan to draw on it informally for feedback, but I’m not applying on behalf of [Code Club](https://codeclub.org/en/){:target="_blank" rel="noopener"} or the [Raspberry Pi Foundation](https://www.raspberrypi.org/){:target="_blank" rel="noopener"}.

**Which stage best describes your project?**

> **Start** — You have an idea but nothing built yet, and you want to create a proof of concept. Your project addresses a specific issue, or one part of a larger problem. You are an individual or a small team keen to learn about Solid by building something with it.

**Please expand on your choice of project stage**, stating any other considerations we should take into account or if you feel you are between stages.
> This is a Start-stage project: nothing is built yet. I have a clear set of use cases, split into must-haves and stretch goals, and a provisional architecture: a Scratch editor and a sharing dashboard that keep projects and consent decisions in Pods, and a small, replaceable agent that carries those decisions out. I'd value the ODI's help testing that design against real Solid servers. I'll use synthetic data rather than real children's Pods. A natural next step would be a pilot with the Code Club I run.
>
> (max 100 words)
> {: .word-count}
{: data-word-limit="100"}

**Please share a brief description of your project.**

What is your project, who is it for, what problem are you aiming to solve, and how does Solid fit into the solution?

> Satchel gives a child a portable record of their coding work on the coding tool, Scratch ([scratch.mit.edu](https://scratch.mit.edu/){:target="_blank" rel="noopener"}), controlled by them and their family.
>
> It is primarily aimed at children learning to code through community programmes like Code Club, and their parents and guardians. A child's Scratch projects are saved to their own Solid Pod, and a sharing dashboard lets the child and their guardian decide *together* who else can see them.
>
> Today that record is fragile: when a teacher's Scratch class goes inactive, Scratch closes the student accounts, and unshared projects are lost unless downloaded one-by-one (see [https://mitscratch.freshdesk.com/en/support/solutions/articles/4000228128-can-i-use-my-student-account-after-my-class-has-ended-](https://mitscratch.freshdesk.com/en/support/solutions/articles/4000228128-can-i-use-my-student-account-after-my-class-has-ended-){:target="_blank" rel="noopener"}).
>
> Additionally, Scratch offers only one permissions switch: private, or public globally. In my Code Club, projects are shown to the room at the end of every session, but nothing lets a child share with the club without sharing with the whole internet.
>
> Solid fits because it separates the app from the storage. In the past, centralised learner-record schemes like the US inBloom initiative have failed, largely because parents wouldn't trust one organisation holding children's data (see [https://datasociety.net/research-library/the-legacy-of-inbloom/](https://datasociety.net/research-library/the-legacy-of-inbloom/){:target="_blank" rel="noopener"}). With Solid, the record stays in the child's Pod, and the only service Satchel runs holds none of the children's work and can be replaced.
>
> Must-have use cases:
>
> - Save and load Scratch projects to a Pod.
> - Share a project, read-only, with a club rather than the whole world.
> - A share needs both the child and a linked guardian to agree; either can revoke alone.
> - Grantees are notified when access starts or ends.
>
> Possible stretch goals: an independent project index; sharing with people who have no Pod; Satchel-hosted Pods; a signed audit log; time-limited grants.
>
> Solid can't natively require two approvals or expire a grant, so alongside a reusable core package and consent vocabulary, I'll publish candid findings on those gaps.
>
> (max 300 words)
> {: .word-count}
{: data-word-limit="300"}

**What are the intended impacts of your project, and how do you intend to measure them?**

> **Primary impact**: showing children's coding work can live under child-and-family control, not a platform's, with a reusable core package and consent vocabulary for other education tools.
>
> **Secondary impact**: documenting where Solid does and doesn't yet support children's data governance (two-party approval, expiring grants, replaceable helper services).
>
> **Who benefits**: families and the Solid and education communities, not me or any company; I have no commercial plans for Satchel.
>
> Success measures:
>
> 1. must-have use cases working end to end on ODI-hosted Pods;
> 1. a non-technical parent granting and revoking unaided;
> 1. feedback from club leaders and parents;
> 1. the packages, vocabulary and findings published openly.
>
> (max 100 words)
> {: .word-count}
{: data-word-limit="100"}

**Please share a rough project roadmap** with key goals, dates, or other project considerations. These can be estimates.
> **Nov–Dec 2026**: Adoption and Implementation Roadmap workshops; test the architecture against the ODI's servers; draft the vocabulary; a risk review against the [ICO Children's Code](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/){:target="_blank" rel="noopener"}.
>
> **Jan 2027**: Scratch save/load to a Pod, and the core package.
>
> **Feb**: sharing dashboard and agent: two-party approval, revocation and notifications.
>
> **Mar**: finish must-haves, then attempt stretch goals; informal feedback from Code Club leaders and parents.
>
> **Apr**: document and publish the packages, vocabulary and findings; demo video and blog post for ODI advocacy.
>
> **Oct**: (six months after support period ends) submit report demonstrating project outcomes
>
> (max 100 words)
> {: .word-count}
{: data-word-limit="100"}

**Please describe your current technical stack, if any.**
> Nothing is built yet. My general stack is JavaScript/TypeScript (Node.js, React). This is the provisional architecture I'd like to validate with the ODI (more detail on the project website):
>
> - **Editor**: a fork of `scratch-gui`, from the AGPL-3.0 `scratch-editor` monorepo, with a thin layer to log in, and to save and load complete `.sb3` files (assets included) to the child's Pod.
> - **Core package**: TypeScript, under an MIT licence, holding everything that isn't Scratch-specific: the Pod layout, requests, decisions, guardian links, and the rule that decides whether a share is approved. All three apps use it; it's built on Inrupt's JavaScript client libraries.
> - **Dashboard**: a client-side app where the child and guardian request, approve and revoke shares. Each person's decisions are stored in their own Pod.
> - **Agent**: a small Node service with its own WebID. It compares the grants that should exist with those that do, writes and removes WAC or ACP grants, tells grantees through Linked Data Notifications and email, and logs each step in the child's Pod. Its only state, a list of registered Pods, lives in its own Pod, so it could theoretically be replaced.
> - **Vocabulary**: where possible reuses existing vocabularies ([DPV](https://w3id.org/dpv/){:target="_blank" rel="noopener"}, [FOAF](https://xmlns.com/foaf/spec/){:target="_blank" rel="noopener"}, [RELATIONSHIP](https://purl.org/vocab/relationship/){:target="_blank" rel="noopener"}, [ODRL](https://www.w3.org/TR/odrl-model/){:target="_blank" rel="noopener"}, [PROV-O](https://www.w3.org/TR/prov-o/){:target="_blank" rel="noopener"} and [schema.org](https://schema.org/){:target="_blank" rel="noopener"}) and adds a small guardian/dependent extension.

**What type of technical support do you require?**
> **Project-Specific (PS)**: validating the architecture; peer programming on Solid authentication and access control for a child's Pod with a separately authenticated guardian and a service agent acting on their decisions.
>
> **Domain-Specific (DS)**: reviewing and publishing the guardianship and consent vocabulary as a reusable data model for other children's education tools. I'd also value early input from the ODI on what a safeguarding and data-protection review should cover before any real child's Pod is involved, even at pilot stage.
>
> **Open-Source (OS)**: guidance on publishing Satchel in a way that provides maximum benefit to the Solid community.

**Please provide a link to your website, if available.**
> [satchel.viboko.dev](https://satchel.viboko.dev){:target="_blank" rel="noopener"}

<!-- markdownlint-disable-next-line MD033 -->
<script src="{{ '/assets/js/word-count.js' | relative_url }}"></script>
