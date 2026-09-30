---
layout: page
title: "Satchel: adding Solid storage to Scratch"
description: >-
  What the Satchel prototype actually builds, how the pieces fit together,
  how a project gets from a child's editor to their Code Club, and the
  problems in today's children's-data model it's meant to demonstrate a
  fix for.
permalink: /what-is-satchel/
---

The core proof of concept is a **storage adapter that lets Scratch save and
load projects to and from a [Solid](/what-is-solid/) Pod**, instead of a
platform's own servers — plus a **consent-and-sharing layer** built on top of
it: a dashboard where a child and their guardian, together, grant and revoke
access to that work, and a small agent that carries out what they decide.

[Scratch](/what-is-scratch/) is the concrete tool it's
built and tested against, but the same pattern is meant to generalise to any
tool that produces a child's learning data — see
[Beyond Scratch](/beyond-scratch/) for that wider argument, and
[How this differs from previous attempts](/how-this-differs/) for why
Pod-based storage specifically, rather than any portable record.

Jump to: [What's being built](#built) &middot;
[How it fits together](#architecture) &middot;
[How it works, step by step](#steps) &middot;
[What problems this solves](#problems) &middot;
[Licensing](#licensing) &middot;
[Out of scope](#out-of-scope)

## What's being built {#built}

1. **Solid Pod save and load, built into Scratch itself.** Built on top of
   [scratch-editor](https://github.com/scratchfoundation/scratch-editor){:target="_blank" rel="noopener"},
   the open-source project behind the Scratch editor — specifically its
   `scratch-gui` package — rather than a separate editor written from
   scratch. The changes are kept deliberately thin: a login button, "save
   to your Pod" and "open from your Pod", and a small adapter that hands
   Scratch's project file to the reusable package below. The UX of saving
   and loading matters as much as the plumbing, for both the child doing
   the saving and the parent or guardian setting the whole thing up —
   something nobody can actually use isn't a demonstration of anything.
2. **A reusable core package.** Everything that isn't specific to Scratch —
   where things live in a Pod, saving and loading a piece of work, share
   requests, decisions, guardian links, and the single rule that decides
   whether a share is approved — lives in one small package that the
   editor, the dashboard and the agent all use. It's not a general-purpose
   "Solid SDK" — that promises more than a Start-tier prototype can
   responsibly deliver — but it is the pattern another tool could pick up:
   a music or writing app would reuse it as-is and write its own small
   adapter in place of the Scratch one. The editor fork has to share
   Scratch's AGPL licence; keeping Scratch out of this package lets it use
   a permissive licence instead.
3. **A sharing dashboard, built on a two-party consent model.** Both the
   child and their guardian have to agree before a share takes effect, and
   either can revoke it again on their own, at any time. Each person's
   decisions are stored in *their own* Pod, so neither can record a
   decision on the other's behalf. A guardian with more than one child sees
   all of their requests in one place.
4. **A small, replaceable Satchel agent.** A service with its own Solid
   identity, which the family grants specific rights in the child's Pod. It
   checks that both have agreed, then grants or removes access, tells the
   people involved, and records each step in an audit log in the child's
   Pod. It holds no passwords and none of the children's work; the only
   thing it keeps is a list of the Pods that signed up, stored in its own
   Pod. Because everything else it needs lives in the family's Pods, a
   family could swap it for an agent run by someone else — their Code Club,
   say — and nothing would be lost.
5. **The vocabulary behind it, published.** The actual data vocabulary used
   to describe guardianship, requests, decisions and the audit log (see
   [Built on existing vocabularies](#vocabularies) below), published as
   something another project could import, rather than only prose
   describing it. That's what lets a different dashboard or a different
   agent work with the same Pods.
{: .built-list}

## How it fits together {#architecture}

Three apps, a shared core package, and the Pods. The editor and dashboard
run in the user's browser and act as whoever is logged in; the agent runs on
a server and acts as itself. Everyone, the agent included, logs in through
an ordinary Solid server, which also stores the Pods and enforces their
access rules — during the prototype, one hosted by the ODI. The dotted
lines show which apps use the core package; the solid ones show what each
app reads, writes or sends.

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
flowchart LR
    accTitle: How Satchel's components depend on each other
    accDescr: Three apps (the Satchel editor, the Satchel dashboard and the Satchel agent) all use a shared core package and vocabulary. The editor saves and loads projects in the child's Pod. The dashboard writes requests and decisions into the child's and guardian's Pods, and registers and pings the agent. The agent reads the child's and guardian's Pods, writes access grants and log entries into the child's Pod, keeps its registry in its own Pod, and tells people about shares through a Solid inbox message or by email.

    subgraph apps["Apps in the browser"]
        Editor["Satchel editor<br/>(Scratch + adapter)"]
        Dashboard["Satchel dashboard"]
    end

    Agent["Satchel agent<br/>(its own identity)"]
    Core["Core package<br/>+ vocabulary"]

    subgraph solid["Solid server (ODI-hosted)"]
        ChildPod[("Child's Pod")]
        GuardianPod[("Guardian's Pod")]
        AgentPod[("Agent's Pod")]
    end

    Notify["Notifications<br/>(Solid inbox, email)"]

    Editor & Dashboard & Agent -.-> Core

    Editor -- "projects" --> ChildPod
    Dashboard -- "requests,<br/>decisions" --> ChildPod
    Dashboard -- "decisions" --> GuardianPod
    Dashboard -- "register,<br/>ping" --> Agent
    Agent -- "grants, log" --> ChildPod
    Agent -- "reads" --> GuardianPod
    Agent -- "registry" --> AgentPod
    Agent -- "tell people" --> Notify
</div>
<!-- markdownlint-enable MD033 -->

A few principles hold the design together:

- **No part of Satchel holds anyone's password.** Each person logs in with
  their own Solid provider, and the app acts *as them*, with a short-lived
  token that stays in their browser.
- **The Pod enforces the outcome; Satchel enforces the process.** Whether
  the Code Club *can open* a project is enforced by the Pod server itself.
  Whether both child and guardian *agreed first* is a rule the agent checks
  and records.
- **The agent reconciles rather than remembers.** It doesn't keep its own
  record of what it has done. It compares the grants that *should* exist,
  according to the requests and decisions in the Pods, with the grants that
  *do* exist, and fixes any difference, writing each step to the log. Any
  agent reading the same Pods would reach the same answer — which is what
  makes it replaceable.

## How it works, step by step {#steps}

One project's journey, from a guardian first being linked to a Code Club
seeing it on the projector — and then what happens when either of them
changes their mind.

### "Nothing of mine should be shareable until a guardian is linked" {#setup}

A child's Pod can exist, holding real work, before any guardian is linked
to it. In that state nothing can be shared — the work stays private, in the
same way an unshared `scratch.mit.edu` project already is. Linking needs
*both* sides: the child's Pod says who their guardian is, and the guardian's
Pod says whose guardian they are. Neither can claim the relationship alone.

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: Linking a guardian and signing up to the agent
    accDescr: The child logs in to the dashboard and names their guardian, which records the link in the child's Pod and gives the guardian read access. The child also names the agent that will manage their shares and gives it specific access. The guardian logs in and confirms the link from their side, in their own Pod, adding a contact email and giving the agent read access. The dashboard then registers the child's Pod with the agent, which checks that it really has been given access before adding the Pod to the registry in its own Pod.
    autonumber
    actor Child
    actor Guardian
    participant Dash as Dashboard
    participant CPod as Child's Pod
    participant GPod as Guardian's Pod
    participant Agent as Satchel agent
    participant APod as Agent's Pod

    Child->>Dash: Log in, name my guardian
    Dash->>CPod: Record "G is my guardian"
    Dash->>CPod: Let the guardian see my Satchel folder
    Dash->>CPod: Name the agent, and give it its access
    Guardian->>Dash: Log in, confirm "I am this child's guardian"
    Dash->>GPod: Record "I am guardian of C", plus a contact email
    Dash->>GPod: Let the agent read my Satchel decisions
    Dash->>Agent: Register the child's Pod
    Agent->>CPod: Check, as itself, that it really has access
    Agent->>APod: Add the child's Pod to the registry
    Agent->>CPod: Log: guardian linked
</div>
<!-- markdownlint-enable MD033 -->

### "Save my project somewhere that's mine" {#save}

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: The child creates and saves a project
    accDescr: The child logs in from the Satchel editor. The editor sends them to their own Solid login page and gets back a short-lived token for the child's identity; Satchel never sees the password. When the child saves, the editor turns the project into a Scratch file and the core package writes it, with a small description and thumbnail, into its own folder in the child's Pod. The Pod checks that the child is its owner and accepts it.
    autonumber
    actor Child
    participant Editor as Satchel editor
    participant Core as Core package
    participant IdP as Child's Solid login
    participant CPod as Child's Pod

    Child->>Editor: Click "Log in"
    Editor->>IdP: Send the child to their own login page
    Child->>IdP: Username and password
    IdP-->>Editor: Short-lived token for the child
    Note over Editor,IdP: Satchel never sees the password
    Child->>Editor: File, Save to your Pod
    Editor->>Core: Save "Cat Maze" (the Scratch file, plus a description)
    Core->>CPod: Write projects/cat-maze/ (project, description, thumbnail)
    CPod->>CPod: Child is the owner, so allowed
    CPod-->>Editor: Saved
</div>
<!-- markdownlint-enable MD033 -->

Each project gets its own folder, so a single grant later covers the
project and everything that describes it. At this point only the child,
and their guardian, can see it.

### "Share my Code Club project with the club, not the whole internet" {#request}

At the end of every Code Club session, the projects children have worked on
are shown to the room on a projector — and today, the only lever Scratch
gives a child is a platform-wide "share" switch, with nothing between "only
I can see it" and "anyone on the internet can see it, forever." Modelling
the club as its own identity, one that can hold a grant for a single
project, closes that gap directly.

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: The child asks to share a project with their Code Club
    accDescr: The child asks the dashboard to share Cat Maze with the Code Club, read-only. The dashboard writes the request into the child's Pod, along with the child's own approval, then pings the agent. The agent reads both Pods and finds the child has approved but the guardian hasn't decided yet, so there is no access to grant. The log shows the guardian hasn't been asked yet, so the agent emails them, then logs that it has.
    autonumber
    actor Child
    participant Dash as Dashboard
    participant CPod as Child's Pod
    participant GPod as Guardian's Pod
    participant Agent as Satchel agent
    actor Guardian

    Child->>Dash: Share "Cat Maze" with Code Club, read-only
    Dash->>CPod: Write the request, and the child's approval
    Dash->>Agent: Ping: check this child's Pod
    Dash-->>Child: "Waiting for your guardian"
    Agent->>CPod: Read requests, decisions, access rules and log
    Agent->>GPod: Read the guardian's decisions
    Note over Agent: Child approved, guardian hasn't decided.<br/>Nothing to grant yet
    Agent-->>Guardian: Email: "Your child would like to share a project"
    Agent->>CPod: Log: guardian asked
</div>
<!-- markdownlint-enable MD033 -->

### "Let my child and me both have a real say, not just me" {#approve}

A share only takes effect once *both* the child and the guardian have
agreed. Because nothing is shared until both sides have said yes, there's
no separate moment where a child needs to veto something that's already
happened — non-agreement simply means nothing happens.

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: The guardian approves, and the Code Club is given access
    accDescr: The guardian follows the email link, logs in to the dashboard, previews the project and approves. The approval is written into the guardian's own Pod, and the dashboard pings the agent. The agent reads both Pods and finds both approvals and a two-way guardian link, so the share should exist but doesn't yet. It gives the Code Club read access to that one project's folder, logs the grant, tells the Code Club through its Solid inbox and by email, tells the child and guardian, and logs that everyone has been told.
    autonumber
    actor Guardian
    participant Dash as Dashboard
    participant GPod as Guardian's Pod
    participant CPod as Child's Pod
    participant Agent as Satchel agent
    participant Club as Code Club

    Guardian->>Dash: Follow the link, log in, preview "Cat Maze"
    Guardian->>Dash: Approve
    Dash->>GPod: Write the guardian's approval
    Dash->>Agent: Ping: check this child's Pod
    Agent->>CPod: Read requests, decisions, access rules and log
    Agent->>GPod: Read the guardian's decisions
    Note over Agent: Both approved, guardian link holds.<br/>The share should exist, and doesn't yet
    Agent->>CPod: Let the Code Club read projects/cat-maze/
    Agent->>CPod: Log: shared, citing both approvals
    Agent-->>Club: Solid inbox message, and email: "You can now see Cat Maze"
    Agent-->>Guardian: Email the child and guardian: "Shared with Code Club"
    Agent->>CPod: Log: everyone told
</div>
<!-- markdownlint-enable MD033 -->

### "Show it on the projector at the next session" {#open}

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: The Code Club opens the project
    accDescr: The club leader opens the link from the notification, logs in to the Satchel editor as the Code Club, and the editor asks the child's Pod for the project. The Pod checks its access rules. If the grant exists, the project loads and runs on the projector, read-only. If there's no grant yet, or it has been taken away, the Pod refuses and the editor says the club doesn't have access.
    autonumber
    actor Leader as Club leader
    participant Editor as Satchel editor
    participant CPod as Child's Pod

    Leader->>Editor: Open the link, log in as the Code Club
    Editor->>CPod: Fetch projects/cat-maze/ as the Code Club
    CPod->>CPod: Check the access rules
    alt The share exists
        CPod-->>Editor: The project
        Editor-->>Leader: Runs on the projector, read-only
    else Not shared yet, or taken away
        CPod-->>Editor: Refused
        Editor-->>Leader: "You don't have access to this project"
    end
</div>
<!-- markdownlint-enable MD033 -->

The club never gets a copy stored anywhere Satchel controls: the project is
fetched straight from the child's Pod, each time, and only while the share
exists.

### "Take access away again, whenever I decide to — and so should my child" {#revoke}

Either the child or the guardian can revoke a share on their own, at any
time, without needing the other's agreement. And the person it was shared
with is told, rather than left to discover it as an unexplained error.

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: Either party revokes a share
    accDescr: The child or the guardian revokes the share in the dashboard. The revocation is written into their own Pod, and the dashboard pings the agent. The agent finds the share has been revoked, so it should no longer exist, but the grant is still there. It removes the Code Club's access, logs who revoked it, tells the Code Club, the child and the guardian, and logs that they have been told.
    autonumber
    actor Party as Child or guardian
    participant Dash as Dashboard
    participant Own as Their own Pod
    participant Agent as Satchel agent
    participant CPod as Child's Pod
    participant Club as Code Club

    Party->>Dash: Stop sharing "Cat Maze" with Code Club
    Dash->>Own: Write the revocation
    Dash->>Agent: Ping: check this child's Pod
    Agent->>CPod: Read requests, decisions, access rules and log
    Agent->>Own: Read the revocation
    Note over Agent: Revoked by one side, which is enough.<br/>The grant still exists
    Agent->>CPod: Remove the Code Club's access
    Agent->>CPod: Log: revoked, and by whom
    Agent-->>Club: Solid inbox message, and email: "Access has ended"
    Agent-->>Party: Email the child and guardian
    Agent->>CPod: Log: everyone told
</div>
<!-- markdownlint-enable MD033 -->

### "Move to a different agent without losing anything" {#replace}

Satchel's agent isn't a custodian the family depends on. Everything it
works from — requests, decisions, access rules and the log — is in the
family's Pods, so another agent that understands the same vocabulary can
simply take over.

<!-- markdownlint-disable MD033 -->
<div class="mermaid">
sequenceDiagram
    accTitle: Replacing the agent
    accDescr: The family chooses a new agent in the dashboard. The dashboard gives the new agent the same access in both Pods, names it as the child's agent, removes the old agent's access, and registers the child's Pod with the new agent. The new agent checks the Pod, finds every share and notification already up to date, and waits for something to change. On its next check, the old agent is refused and drops the Pod from its registry.
    autonumber
    actor Family as Child and guardian
    participant Dash as Dashboard
    participant Pods as Child's and guardian's Pods
    participant Old as Old agent
    participant New as New agent

    Family->>Dash: Switch to a new agent
    Dash->>Pods: Give the new agent the same access
    Dash->>Pods: Name the new agent as the child's agent
    Dash->>Pods: Remove the old agent's access
    Dash->>New: Register the child's Pod
    New->>Pods: Check everything
    Note over New: Same requests, decisions, grants and log.<br/>Nothing to do until something changes
    Old->>Pods: Next routine check
    Pods-->>Old: Refused
    Old->>Old: Drop the child's Pod from its registry
</div>
<!-- markdownlint-enable MD033 -->

## What problems this solves {#problems}

- **Portability.** A child's work shouldn't be locked to whichever club,
  school or platform's servers happened to host the session it was made in.
  Scratch's own student accounts show the risk: when a class ends or the
  teacher becomes inactive, the account is
  [automatically closed](https://mitscratch.freshdesk.com/en/support/solutions/articles/4000228128-can-i-use-my-student-account-after-my-class-has-ended-){:target="_blank" rel="noopener"},
  the student loses access to their unshared projects, and getting anything
  back means asking Scratch for a conversion or manually downloading each
  project as an `.sb3` file beforehand.
- **No single trusted custodian — a step further than portability alone.**
  A record can be portable and still be centralised — a "backpack" a child
  carries between institutions, say — without solving the actual trust
  problem, which is that a single organisation holding children's data at
  scale is what families don't trust, regardless of that organisation's
  intentions. Solid's Pod model never puts the data in one place to begin
  with, and the only service Satchel itself runs holds none of the
  children's work, no passwords, and can be replaced. See
  [How this differs from previous attempts](/how-this-differs/) for the
  fuller argument.
- **Granularity of permissions.** Scratch's own model is a single binary
  switch, plus a one-time consent gate at sign-up — there's no way to share
  one project with one audience. Per-project, per-person, revocable grants
  replace that single switch.
- **Consent that represents the child, not just the parent.** A model where
  only a parent's decision is ever recorded risks treating "the family" as
  one undifferentiated interest, with no way to capture a child's own view
  — including a child's disagreement with a guardian's decision. Requiring
  both the child and the guardian to agree, and letting either revoke
  unilaterally, is this project's concrete answer: a real,
  independently-recorded say for the child, not just a parent dashboard.
- **Guardian authority that's recorded, not inherited.**{: #guardian-not-parent}
  Holding authority over a child's Pod is an explicit relationship,
  confirmed from both sides, never something automatically inferred from
  being a parent. Two people can both be a child's parent in real life,
  while only one of them has actually linked as their guardian — perhaps
  because onboarding happened through one parent's account. If the second
  parent tries to approve a share, it doesn't count, because family relation
  and guardianship are two separate, independently recorded facts. See the
  [Sovrin Foundation's guardianship model](https://sovrin.org/on-guardianship-in-self-sovereign-identity/){:target="_blank" rel="noopener"}.
- **A record of who decided what, and when.** Every request, approval,
  refusal and revocation is kept, not overwritten, alongside a log of every
  grant the agent made or removed. That's a direct application of a
  guardianship duty the same Sovrin model sets out: keep records of actions
  taken on a dependent's behalf.

## Built on existing vocabularies {#vocabularies}

The data model behind guardianship, consent and sharing isn't a bespoke
format invented for this project — it's built mostly from existing,
widely-used vocabularies, with only a small, genuinely new piece (the
guardian/dependent relationship itself) added on top:

- [DPV](https://w3id.org/dpv/){:target="_blank" rel="noopener"} — the Data
  Privacy Vocabulary, for the child as data subject and the consent-status
  states a share moves through.
- [FOAF](https://xmlns.com/foaf/spec/){:target="_blank" rel="noopener"} — for
  people: children, guardians, family members.
- [RELATIONSHIP](https://purl.org/vocab/relationship/){:target="_blank" rel="noopener"}
  — for family relations like `parentOf`, kept separate from guardianship.
- [ODRL](https://www.w3.org/TR/odrl-model/){:target="_blank" rel="noopener"}
  — for expressing a share request as a policy over a resource, an actor
  and an action.
- [PROV-O](https://www.w3.org/TR/prov-o/){:target="_blank" rel="noopener"} —
  for the audit log: who did what, and when.
- [schema.org](https://schema.org/){:target="_blank" rel="noopener"} — for
  organisations like Code Club, and the apps involved.

Because the agent works only from what's in the Pods, the vocabulary also
defines the shape of requests, decisions and log entries precisely enough
that a different agent could take over from Satchel's.

## Licensing {#licensing}

Everything Satchel produces is intended to be released openly, under one of
three licences:

| Licence | Applies to | Why |
| --- | --- | --- |
| [AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.html){:target="_blank" rel="noopener"} | The Satchel editor | It's a fork of `scratch-gui`, from the `scratch-editor` monorepo, which is itself AGPL-3.0 — so the fork has to be too. |
| [MIT](https://opensource.org/license/mit){:target="_blank" rel="noopener"} | The core package, the dashboard and the agent | None of these include any Scratch code, so they can use a permissive licence, letting another tool pick up the pattern without taking on the AGPL's obligations. |
| [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/){:target="_blank" rel="noopener"} | The vocabulary and documentation | These aren't software, so a Creative Commons licence fits them better than a software licence — anyone can reuse and adapt them, with credit. |

## Out of scope for this prototype {#out-of-scope}

### Stretch goals, if time allows

- **A separate, independently-run project index**, holding only
  descriptions a child chose to publish, never the projects themselves — to
  show that the site hosting an editor and the site helping people discover
  a project don't have to be the same organisation.
- **Sharing with people who don't have a Pod.** Most family members don't,
  and Solid can only grant access to someone with a Solid identity. The
  likeliest answer is a simple invitation that creates one for them.
- **Satchel-hosted Pods**, so a family can sign up with an ordinary login
  and never need to know Solid exists — while still being able to see their
  Pod, and move it to another provider. The honest trade-off: if most
  families accept the default, Satchel becomes the main host of their data,
  so the claim becomes "no lock-in" rather than "no central host".
- **A signed log, mirrored into the guardian's Pod**, so a party who edits
  their own copy can be caught out. Even then it's tamper-*evident*, not
  tamper-*proof*: someone who controls their own Pod outright could rewrite
  it from scratch and re-sign a fabricated history. Fully defeating that
  would need a neutral third party holding an independent copy — exactly
  the kind of trusted custodian this project argues against elsewhere.
- **Time-limited grants** — sharing a term's projects with a visiting
  relative for two weeks, say. Neither of Solid's access-control languages
  has a built-in expiry, so this needs the agent to remove the grant on
  time; Inrupt's Access Grants, which do expire, are worth comparing.

### Not attempted

- Write access or real-time collaboration between children — every grant in
  this model is read-only. Letting two children edit the same project raises
  a different, harder set of problems (conflict handling, offline editing)
  that would dilute the argument this prototype is actually making.
- Real membership administration for Code Club — the prototype's "club" is a
  single identity the club leader logs in as, not a moderated membership
  system.
- Stopping the child bypassing the process. The child owns their Pod, so
  they could change its access rules directly with another Solid app. The
  agent logs any access it didn't create, so this is detectable, but it
  can't be prevented without taking ownership of the Pod away from the
  child.
- Stopping onward sharing. Once a grantee can open a project, they could
  save a copy — as with any sharing system.
- Recovering a lost Pod or lost credentials — a real risk for a record
  meant to last decades, and not one this prototype attempts to solve.
- Verifying that a guardian relationship is real. A "guardian" in this
  prototype is, in practice, whoever completes the linking step — much
  like a "parent" on `scratch.mit.edu` today is just whoever holds the
  email address used at sign-up. This prototype doesn't improve on that.
  The [Sovrin Foundation's Guardianship Working Group](https://sovrin.org/on-guardianship-in-self-sovereign-identity/){:target="_blank" rel="noopener"}
  is the closest real effort trying to solve it properly — legally-backed
  guardianship credentials, not just a login — and is worth folding in as
  a future direction rather than something this prototype attempts itself.
- How the relationship changes over time: a child gaining more say as they
  get older, guardianship ending at adulthood, or a change of guardian.
  These matter for any real deployment, and are future work.

{% include mermaid.html %}
