---
layout: post
title: "Satchel: Initial investigations"
description: >-
  Where Satchel stands in October 2026: a first working prototype that saves
  a Scratch project to a Solid Pod, how it's built, what it doesn't do yet,
  what comes next, and where the ODI could help.
permalink: /updates/2026-10-25-satchel-initial-investigations/
# Shared directly ahead of the ODI interview: not linked from the rest of the
# site, left out of the sitemap, and asking search engines not to index it.
noindex: true
sitemap: false
# Where the code snippets are quoted from: a pushed commit on the fork's
# satchel-demo branch, so their line numbers and links stay accurate.
code_source:
  repo: viboko/scratch-editor
  ref: 5f27c5d53cbc8f7775c21634718d641ebaa5115a
---

<!-- Code snippets and the video, diagram and transcript are HTML, or look
     like it to markdownlint. -->
<!-- markdownlint-disable MD033 -->

Since applying to the [Solid open call](https://theodi.org/news-and-events/blog/solid-open-call/){:target="_blank" rel="noopener"},
I've done two things:

- **Planned Satchel.** [What is Satchel](/what-is-satchel/) sets out what
  it will build and how the pieces fit together.
- **Saved a Scratch project to a Solid Pod.** My fork of the Scratch editor
  can now save a project into the user's own Pod, demonstrated in
  [viboko/scratch-editor#3](https://github.com/viboko/scratch-editor/pull/3){:target="_blank" rel="noopener"}.

## How the editor is built {#how-its-built}

### A fork of Scratch's own editor

The editor is a fork of
[scratchfoundation/scratch-editor](https://github.com/scratchfoundation/scratch-editor){:target="_blank" rel="noopener"},
the monorepo behind the real Scratch editor, at
[viboko/scratch-editor](https://github.com/viboko/scratch-editor){:target="_blank" rel="noopener"}.
Satchel's work lives on its `satchel` branch, and upstream changes are merged
into it regularly so the fork doesn't drift. All the changes are in the
`scratch-gui` package, and they're kept small on purpose: the smaller the
fork, the easier it is to keep up with Scratch.

Solid saving is switched on with a single new prop, `canSaveToSolid`. Without
it, the editor behaves exactly as before. The demo page turns it on:

{% code_snippet lang="jsx" path="packages/scratch-gui/src/playground/solid-save-demo.jsx" start=23 %}
root.render(
    <WrappedGui
        canEditTitle
        canSaveToSolid
        onClickLogo={onClickLogo}
    />
);
{% endcode_snippet %}

With the prop set, File > Save now (and Ctrl/Cmd+S) opens a "Save to your
Solid Pod" dialog instead of saving to Scratch's servers. That's a one-line
change in the menu bar:

{% code_snippet lang="jsx" path="packages/scratch-gui/src/components/menu-bar/menu-bar.jsx" start=779 %}
    onClickSave: () => dispatch(ownProps.canSaveToSolid ? openSolidSaveModal() : manualUpdateProject()),
{% endcode_snippet %}

The rest is four new files, all in `packages/scratch-gui/src/`:

| File | What it does |
| --- | --- |
| [`lib/solid-save.ts`](https://github.com/viboko/scratch-editor/blob/satchel/packages/scratch-gui/src/lib/solid-save.ts){:target="_blank" rel="noopener"} | Talks to Solid: logs in, finds the user's Pod, and writes the project to it. |
| [`lib/solid-pending-save.ts`](https://github.com/viboko/scratch-editor/blob/satchel/packages/scratch-gui/src/lib/solid-pending-save.ts){:target="_blank" rel="noopener"} | Keeps the project safe in the browser while the user is away logging in. |
| [`containers/solid-save-modal.jsx`](https://github.com/viboko/scratch-editor/blob/satchel/packages/scratch-gui/src/containers/solid-save-modal.jsx){:target="_blank" rel="noopener"} | Runs the save from the editor: starts the login, finishes the save when the user comes back, and puts the project back into the editor. |
| [`components/solid-save-modal/solid-save-modal.jsx`](https://github.com/viboko/scratch-editor/blob/satchel/packages/scratch-gui/src/components/solid-save-modal/solid-save-modal.jsx){:target="_blank" rel="noopener"} | The "Save to your Solid Pod" dialog, where the user enters their WebID. |

It's built on Inrupt's
[`@inrupt/solid-client`](https://www.npmjs.com/package/@inrupt/solid-client){:target="_blank" rel="noopener"}
and [`@inrupt/solid-client-authn-browser`](https://www.npmjs.com/package/@inrupt/solid-client-authn-browser){:target="_blank" rel="noopener"}
libraries.

### Logging in means leaving the page

The awkward part of saving to Solid from a browser app is that logging in
redirects the whole page to the user's Solid provider and back. Anything only
held in memory, like the project the child is working on, is lost on the
way. So a first save spans two page loads:

<div class="mermaid">
sequenceDiagram
    accTitle: Saving to a Solid Pod for the first time
    accDescr: The child clicks Save now and enters their WebID. The editor reads the WebID's profile to find their Solid login provider, stashes the project in the browser's IndexedDB, and redirects to the provider. The child logs in and authorises Scratch. The provider redirects back to the editor, which completes the login, takes the stashed project, writes it into a scratch folder in the child's Pod, and puts the project back into the editor.
    autonumber
    actor Child
    participant Editor as Scratch editor
    participant IDB as Browser storage<br/>(IndexedDB)
    participant IdP as Child's Solid provider
    participant Pod as Child's Pod
    Child->>Editor: File, Save now, enter WebID
    Editor->>Pod: Read the WebID profile
    Pod-->>Editor: Login provider (solid:oidcIssuer)
    Editor->>IDB: Stash the project
    Editor->>IdP: Redirect to log in
    Child->>IdP: Log in, authorise Scratch
    IdP-->>Editor: Redirect back, with a token
    Editor->>IDB: Take the stashed project
    Editor->>Pod: Write scratch/satchel.json
    Editor-->>Child: "Saved", project back in the editor
</div>

Before redirecting, the editor finds the user's login provider from their
WebID profile and stashes the project, both as the JSON that gets saved and
as a complete `.sb3` file so it can be put back into the editor afterwards:

{% code_snippet lang="ts" path="packages/scratch-gui/src/lib/solid-save.ts" start=145 %}
export const startSolidSave = async ({webId, title, projectJson, projectSb3, isRenewal = false}: {
    webId: string;
    title: string;
    projectJson: string;
    projectSb3: Blob;
    isRenewal?: boolean;
}): Promise<void> => {
    const oidcIssuer = await resolveOidcIssuer(webId);
    await putPendingSolidSave({webId, isRenewal, title, projectJson, projectSb3});
    await login({
        oidcIssuer,
        redirectUrl: `${window.location.origin}${window.location.pathname}`,
        clientName: 'Scratch'
    });
};
{% endcode_snippet %}

When the page loads again, the editor checks whether it's coming back from a
login, and if a save was waiting, finishes it:

{% code_snippet lang="ts" path="packages/scratch-gui/src/lib/solid-save.ts" start=166 %}
export const completePendingSolidSave = async (): Promise<CompletedSolidSave | null> => {
    const returningFromLogin = new URLSearchParams(window.location.search).has('state');
    // Restoring the previous session is what lets later saves skip the login.
    const sessionInfo = await handleIncomingRedirect({restorePreviousSession: true});
    if (!returningFromLogin) return null;

    const pending = await takePendingSolidSave();
    if (!pending) return null;

    const {webId, isRenewal, title, projectJson, projectSb3} = pending;
    if (!sessionInfo?.isLoggedIn) {
        return {
            outcome: {status: 'error', message: 'The Solid login was not completed.'},
            isRenewal,
            title,
            projectSb3
        };
    }
    rememberWebId(webId);

    try {
        const url = await writeProject(webId, title, projectJson);
        return {outcome: {status: 'saved', url}, isRenewal, title, projectSb3};
    } catch (error) {
        log.error(`completePendingSolidSave: failed to write the project for ${webId}`, error);
        return {outcome: {status: 'error', message: errorMessage(error)}, isRenewal, title, projectSb3};
    }
};
{% endcode_snippet %}

### Writing to the Pod

The write itself is short. It finds the user's Pod from their profile,
makes a `scratch/` folder in it if there isn't one, and writes the project
there, named after its title:

{% code_snippet lang="ts" path="packages/scratch-gui/src/lib/solid-save.ts" start=77 %}
const writeProject = async (webId: string, title: string, projectJson: string): Promise<string> => {
    const {fetch} = getDefaultSession();
    const [podUrl] = await getPodUrlAll(webId, {fetch});
    if (!podUrl) {
        throw new Error(`No Pod storage (pim:storage) is listed in the profile at ${webId}.`);
    }
    const containerUrl = new URL(`${CONTAINER_NAME}/`, podUrl).href;
    await ensureContainer(containerUrl, fetch);

    const fileUrl = new URL(fileNameForTitle(title), containerUrl).href;
    await overwriteFile(fileUrl, new Blob([projectJson], {type: 'application/json'}), {
        contentType: 'application/json',
        fetch
    });
    return fileUrl;
};
{% endcode_snippet %}

The `fetch` here comes from the Solid session, and adds the user's token to
each request. The Pod server, not Scratch, decides whether the write is
allowed: it accepts it because the logged-in user owns the Pod.

### Saving again, and short-lived sessions

Once someone has logged in, later saves go straight to the Pod with no
dialog, just Scratch's usual "Saving…" and "Project saved." alerts.

One thing I learned the hard way: Solid sessions are short-lived. The Inrupt
library only refreshes an access token if the login that produced it
returned a refresh token, and a session silently restored after a page load
doesn't have one. So when a save finds no session, or the Pod rejects the
token with an HTTP 401, the editor logs in again by itself, using the WebID
from the last successful login, rather than showing the dialog again:

{% code_snippet lang="jsx" path="packages/scratch-gui/src/containers/solid-save-modal.jsx" start=124 %}
        saveToSolidPod({title: projectTitle, projectJson})
            .then(() => {
                onShowSaved();
                onClose();
            })
            .catch(error => {
                if (error instanceof SolidSessionExpiredError && getLastSolidWebId() !== '') {
                    return logInAgain().catch(showFailure);
                }
                return showFailure(error);
            });
{% endcode_snippet %}

The dialog only appears for someone who has never logged in, or when a save
genuinely fails.

### Tests and tooling

- **Unit tests.** About 700 lines of Jest tests cover the save logic, the
  pending-save stash (using `fake-indexeddb`), the dialog and its container.
  They run in the fork's CI alongside Scratch's own tests.
- **A local Solid server.** `just css-up` runs a Community Solid Server on
  the developer's own machine, and the fork's README explains how to try the
  whole flow against it.
- **A recorded, scripted demo.** The video below isn't a screen recording
  of me clicking about. It's a [Playwright](https://playwright.dev/){:target="_blank" rel="noopener"}
  script, kept on the fork's [`satchel-demo` branch](https://github.com/viboko/scratch-editor/tree/satchel-demo/demo){:target="_blank" rel="noopener"},
  that starts an empty Solid server, drives both browser tabs, and adds the
  captions. The narration is generated from the same captions by a
  text-to-speech model running locally. Re-running `just demo` re-records the
  whole thing, so the demo can't quietly fall out of step with the code.

## The demo {#demo}

<figure class="video">
  <video controls preload="metadata" width="1280" height="800"
         poster="{{ '/assets/videos/2026-10-25-save-to-pod-demo-poster.webp' | relative_url }}">
    <source src="{{ '/assets/videos/2026-10-25-save-to-pod-demo.mp4' | relative_url }}" type="video/mp4">
    <a href="{{ '/assets/videos/2026-10-25-save-to-pod-demo.mp4' | relative_url }}">Download the demo video (MP4, 3.5 MB)</a>
  </video>
  <figcaption>
    Saving a Scratch project to a Solid Pod, then reading it back with a
    different Solid app. 1 minute 23 seconds, narrated, with on-screen captions.
  </figcaption>
</figure>

What happens in the video:

1. **A brand new Solid server.** A Community Solid Server is running on the
   local machine, with no accounts on it. We sign up, and create a Pod called
   `my-pod`. The Pod comes with a WebID,
   `http://localhost:3000/my-pod/profile/card#me`: the user's identity on the
   Solid web.
2. **The Scratch editor, with Solid saving switched on.** We load a small
   project from the computer and play it: the Scratch cat walks, jumps, and
   picks up a satchel.
3. **Saving to the Pod.** File > Save now opens the "Save to your Solid Pod"
   dialog. We enter the WebID, and Scratch sends us to the Solid server to
   log in.
4. **Authorising Scratch.** The Solid server asks whether Scratch may access
   the Pod. This is the point to notice: the user grants an app access to
   their storage, rather than handing their work to the app.
5. **Back in the editor.** The save finishes, and the project is back
   exactly as it was.
6. **Reading it with a different app.** We sign in to
   [Solid File Manager](https://filemanager.solid-experiments.org/){:target="_blank" rel="noopener"},
   an independent Solid app with no connection to Scratch, using the same
   WebID. It opens the Pod, the `scratch` folder, and `satchel.json`: the
   project Scratch just saved.

That last step is the point of the whole project in miniature. The work
belongs to the person who made it, in storage they control, rather than to
the app they made it in.

<details class="transcript" markdown="1">
<summary>Read the narration</summary>

Here's a brand new Solid server, running locally. First, let's sign up for
an account. Now we create a Pod, and call it "my pod". And the Pod comes with
a Web ID. That's our identity, on the Solid web.

Over to Scratch! This is the editor, with saving to Solid switched on. Let's
load a project from the computer. Click the green flag to run it. Off we go!
Jump! On to the satchel… and, pick it up!

Now, the important bit: saving the project to our Pod. File, then Save now.
Scratch asks for our Web ID, so it knows where to log us in. The Solid server
checks with us: is Scratch allowed to save here? Yes, it is. Saved! And we're
straight back in the editor, right where we left off.

Here's the clever part. The project isn't locked inside Scratch: any Solid
app can reach it. Let's try a file manager. Same Web ID, same Pod. We just
let the file manager in. We're in. Let's open the Pod… then the scratch
folder… and there's the project that Scratch saved. There it is: the very
same project, read back from the Pod, by a completely different app.

</details>

## What the demo doesn't do yet {#gaps}

This is a first slice, and it's worth being plain about what's missing.

- **No loading.** Projects can be saved to a Pod but not opened from one.
  There's no "Open from your Pod" yet, so the only way to see a saved project
  is with another Solid app, as in the demo.
- **The video and code above save only the project's code.** They write
  Scratch's project JSON, which refers to costumes and sounds by their hash
  rather than including them. Since recording, I've changed the save to write
  the complete `.sb3` file instead, costumes and sounds included, so a saved
  project now has everything needed to open it again. The description and
  thumbnail that should sit alongside it aren't written yet.
- **The Solid code lives inside the Scratch fork.** The plan is for
  everything that isn't Scratch-specific (where things go in a Pod, saving
  and loading, and later the sharing rules) to live in a separate core
  package, under the MIT licence, with only a thin adapter in the
  AGPL-licensed fork. Today it's all in `scratch-gui`. That was the quickest
  way to prove the flow, but it's the first thing to change.
- **Nothing about sharing yet.** No guardian linking, no dashboard, no agent,
  no notifications. The saved project is private to its owner, which is the
  right default, but that's all there is so far.
- **Tested only against a local Community Solid Server.** It hasn't been run
  against Inrupt's Enterprise Solid Server, or any hosted Pod.
- **Rough edges in the login.** The user types their WebID by hand, and
  Scratch registers itself with each Solid provider on the fly rather than
  publishing a Client ID Document, so the provider can only show "Scratch"
  as the app's name, unverified.
- **Projects are named by title.** Two projects with the same title
  overwrite each other.

## Next steps {#next-steps}

In roughly this order, fitting the
[roadmap in the application](/application/):

1. **Move the Solid code into the core package.** Split `solid-save.ts` into
   an MIT-licensed core package that knows about Pods but not Scratch, and a
   thin Scratch adapter in the fork. Doing this before adding more features
   keeps the licence boundary honest from the start.
2. **Load from a Pod.** Give each saved `.sb3` its own folder, with a
   description and thumbnail, and add "Open from your Pod". This finishes the
   first must-have.
3. **Test against the ODI's servers.** Run the same flow on ODI-hosted Pods,
   on both servers, and find out early what differs.
4. **Publish a Client ID Document** for the editor, so providers can show
   who's asking for access.
5. **Draft and publish the vocabulary** for guardianship, share requests,
   decisions and the audit log.
6. **Build the sharing dashboard and the agent:** linking a guardian, asking
   to share a project with a Code Club, both child and guardian approving,
   either revoking, and people being told when access starts or ends.
7. **Get informal feedback** from club leaders and parents, using synthetic
   data only, and write up what Solid does and doesn't yet support well.

## How the ODI could help {#odi}

The save flow shows the Solid basics working. The hard, unbuilt parts are
the ones where I'd most value the ODI's help.

### Hosted Pods and test identities

- **Test Pods and WebIDs for every role in the story:** a child (ideally two),
  a guardian, a second parent who is deliberately *not* a linked guardian, a
  Code Club, and the agent, plus a second agent identity to show a family
  switching agents without losing anything.
- **Whether I can create test accounts myself**, or need to request each one.
- **Server settings, checked early:** whether the hosted servers allow
  browser apps on other origins to read and write Pods (CORS), so it doesn't
  turn up as a blocker in the middle of the build.

### Access control: the genuinely hard part

- **WAC or ACP, and which versions?** The servers' access-control language
  decides a lot of the agent's design.
- **Two-party consent.** Solid has no built-in way to require two people to
  agree before access is granted, which is why the design needs an agent.
  I'd value pair-programming and review on whether that pattern is sound, and
  on scoping the agent's Control permission to the Satchel folder only.
- **ACP extension points.** Does the hosted ACP support matching on
  verifiable credentials (`acp:vc`), or a custom attribute the server
  resolves? If not, parts of the consent model fall back to being enforced by
  the application rather than the Pod, which is a weaker guarantee, and I'd
  like to know that before building it.
- **How the agent logs in.** It runs on a server with no browser, so it needs
  client credentials or static registration, and the right approach depends
  on the server.
- **Solid Notifications.** Whether the servers support the notifications
  protocol, so the agent can react to changes in a Pod rather than relying on
  being pinged and on routine checks.

### Workshops: settling the architecture before building

The adoption and implementation-roadmap workshops are the right place to
settle the decisions above (WAC or ACP, how the agent is triggered, how
revocation is recorded) against what the ODI's servers really support,
before February's build work commits to one answer.

### Publishing the vocabulary

The vocabulary mostly reuses existing ones (DPV, ODRL, PROV-O, FOAF,
RELATIONSHIP and schema.org), with a small guardian/dependent extension.
I'd welcome review of it, advice on where to publish it so it lasts (a
persistent namespace such as w3id.org, under CC BY 4.0), and help with open
design questions, such as whether a revoked share should be a new record or
a change of state on the old one.

### Safeguarding, data protection and the Children's Code

This is where I most need expertise I don't have. No real child's data will
be used during the support period. Before any pilot, I'd like the ODI's
input on what a safeguarding and data-protection review (likely including a
Data Protection Impact Assessment) should cover, and early feedback on how
the design fares against the ICO's Children's Code: an agent that holds none
of the children's work, nothing shareable until a guardian is linked, and a
real say for the child alongside the guardian.

### Connections and community

- **Other projects facing similar problems.** Acting on someone's behalf, and
  recovering lost credentials, are unlikely to be problems unique to
  children's data. If others in the cohort have tackled them, I'd like to
  learn from them.
- **Where findings should land.** The Solid forum, the W3C Solid Community
  Group, or the Linked Web Storage Working Group: wherever the findings on
  two-party consent and expiring grants would be most useful.
- **Credibility for a pilot.** A future pilot with Code Club or the Raspberry
  Pi Foundation is far easier to propose with the ODI's backing and a public
  write-up than as a solo developer.

### Mutual, not one-way

The gaps this project runs into, like two-party consent and grants that
expire, are worth documenting whatever happens to Satchel itself. I'd rather
document them accurately, with the ODI engineers' input, than guess.

{% include mermaid.html %}
