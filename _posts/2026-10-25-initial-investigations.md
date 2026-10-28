---
layout: post
title: "Initial investigations"
description: >-
  Where Satchel stands in October 2026: a first working prototype that saves
  a Scratch project to a Solid Pod, how it's built, what it doesn't do yet,
  what comes next, and where the ODI could help.
# Where the code snippets are quoted from: the fork's initial-investigations
# tag, so their line numbers and links stay accurate.
code_source:
  repo: viboko/scratch-editor
  ref: initial-investigations
---

I have an initial working proof-of-concept with demonstrates saving a Scratch project to a Solid pod.

<!-- Code snippets and the video, diagram and collapsed section are HTML, or look
     like it to markdownlint, and the code inside a code_snippet tag looks
     like an indented code block. -->
<!-- markdownlint-disable MD033 MD046 -->

{% assign demo_video = '/assets/videos/2026-10-25-save-to-pod-demo.mp4' | versioned_url %}
<figure class="video">
  <video controls preload="metadata" width="1280" height="800"
         poster="{{ '/assets/videos/2026-10-25-save-to-pod-demo-poster.webp' | versioned_url }}">
    <source src="{{ demo_video }}" type="video/mp4">
    <track kind="captions" srclang="en" label="English"
           src="{{ '/assets/videos/2026-10-25-save-to-pod-demo.vtt' | versioned_url }}">
  </video>
  <figcaption>
    <span>
      Saving a Scratch project to a Solid Pod, finding it with a different
      Solid app, and looking inside it.
    </span>
    <a class="video__download" href="{{ demo_video }}" download
       aria-label="Download the video" title="Download the video">
      <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false"
           fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
           stroke-linejoin="round">
        <path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>
      </svg>
    </a>
  </figcaption>
</figure>

<details class="transcript run-locally" markdown="1">
<summary>How to run the demo locally</summary>

Everything runs on your own machine: a local Solid server, and the Scratch
editor from my fork. These steps were written on macOS, and should work
anywhere the tools below do.

1. **Install the tools.** You'll need [Git](https://git-scm.com/){:target="_blank" rel="noopener"},
   [Node.js](https://nodejs.org/){:target="_blank" rel="noopener"} 24, and
   [just](https://just.systems/){:target="_blank" rel="noopener"}, a command
   runner. On a Mac with Homebrew, you can install just with:

   ```bash
   brew install just
   ```

2. **Clone the fork, at the `initial-investigations` tag, then install and
   build it.** The `nvm install` line picks up the exact Node.js version from the
   fork's `.nvmrc`; leave it out if you don't use
   [nvm](https://github.com/nvm-sh/nvm){:target="_blank" rel="noopener"}. The
   build is only needed once, and takes a few minutes.

   ```bash
   git clone --branch initial-investigations https://github.com/viboko/scratch-editor.git
   cd scratch-editor
   nvm install
   just install
   npm run build
   ```

3. **Start a Solid server.** This runs a
   [Community Solid Server](https://github.com/CommunitySolidServer/CommunitySolidServer){:target="_blank" rel="noopener"}
   at [http://localhost:3000](http://localhost:3000){:target="_blank" rel="noopener"},
   keeping its data in `.css-data`. Leave it running.

   ```bash
   just css-up
   ```

4. **Create an account and a Pod.** Open
   [http://localhost:3000/.account/](http://localhost:3000/.account/){:target="_blank" rel="noopener"},
   choose **Sign up**, and register with any email address and password:
   they only exist on your machine. Then choose **Create pod**, name it
   `my-pod`, and note your WebID:
   `http://localhost:3000/my-pod/profile/card#me`.
5. **Start the Scratch editor.** In a second terminal, in the same folder,
   run:

   ```bash
   just dev
   ```

   Once webpack has finished compiling, open the editor, with Solid saving
   switched on, at
   [http://localhost:8601/solid-save.html](http://localhost:8601/solid-save.html){:target="_blank" rel="noopener"}.
6. **Make something.** Make some changes to the Scratch project: add some
   blocks, draw a costume, record a sound. Give it a title in the box at the
   top, as that becomes its file name in the Pod.
7. **Save it to your Pod.** Choose **File > Save now**, enter your WebID,
   and choose **Continue**. The Solid server asks you to log in, if you
   aren't still logged in from step 4, then whether Scratch may access your
   Pod: choose **Authorize**. You come back to the
   editor, with your project as you left it, and a message saying where it
   was saved. Saving again, with **File > Save now** or Ctrl/Cmd+S, now goes
   straight to the Pod.
8. **Find it with a different app.** Open
   [Solid File Manager](https://filemanager.solid-experiments.org/){:target="_blank" rel="noopener"},
   enter `http://localhost:3000` as your Solid provider, choose **Continue to
   sign in**, and authorize it as before. If Chrome asks whether the site may
   access devices on your local network, allow it: that's how the file
   manager reaches your local Solid server. Open your Pod, then the `scratch`
   folder, and your project is there as an `.sb3` file.
9. **Look inside it.** Right-click the file and choose **Download**. An
   `.sb3` is a zip, so any zip tool can open it (you may need to rename it to
   `.zip` first). Inside are `project.json`, with your scripts and variables,
   and every costume and sound as an ordinary file.

**Note**: To run the demo again from an empty Solid server, stop the server from
step 3 (Ctrl+C in its terminal). Then delete everything it stored, like so:

```bash
just clean
```

</details>

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
it, the editor behaves exactly as before. The demo page turns it on, and
uses a second prop, `solidClientId`, to say where Solid servers can find a
description of the editor (more on that below):

{% code_snippet lang="jsx" path="packages/scratch-gui/src/playground/solid-save-demo.jsx" start=23 %}
root.render(
    <WrappedGui
        canEditTitle
        canSaveToSolid
        solidClientId={`${window.location.origin}/solid-client-id.jsonld`}
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
| [`lib/solid-save.ts`](https://github.com/viboko/scratch-editor/blob/initial-investigations/packages/scratch-gui/src/lib/solid-save.ts){:target="_blank" rel="noopener"} | Talks to Solid: logs in, finds the user's Pod, and writes the project to it. |
| [`lib/solid-pending-save.ts`](https://github.com/viboko/scratch-editor/blob/initial-investigations/packages/scratch-gui/src/lib/solid-pending-save.ts){:target="_blank" rel="noopener"} | Keeps the project safe in the browser while the user is away logging in. |
| [`containers/solid-save-modal.jsx`](https://github.com/viboko/scratch-editor/blob/initial-investigations/packages/scratch-gui/src/containers/solid-save-modal.jsx){:target="_blank" rel="noopener"} | Runs the save from the editor: starts the login, finishes the save when the user comes back, and puts the project back into the editor. |
| [`components/solid-save-modal/solid-save-modal.jsx`](https://github.com/viboko/scratch-editor/blob/initial-investigations/packages/scratch-gui/src/components/solid-save-modal/solid-save-modal.jsx){:target="_blank" rel="noopener"} | The "Save to your Solid Pod" dialog, where the user enters their WebID. |

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
    Editor->>Pod: Write scratch/satchel.sb3
    Editor-->>Child: "Saved", project back in the editor
</div>

Before redirecting, the editor finds the user's login provider from their
WebID profile and stashes the project as a complete `.sb3` file, so it can be
saved and put back into the editor afterwards. The login names a Client ID
Document: a small public file describing the editor, which the Solid server
reads each time someone logs in, so Scratch never has to register itself with
the server first:

{% code_snippet lang="ts" path="packages/scratch-gui/src/lib/solid-save.ts" start=145 %}
export const startSolidSave = async ({webId, title, projectSb3, isRenewal = false, clientId}: {
    webId: string;
    title: string;
    projectSb3: Blob;
    isRenewal?: boolean;
    clientId?: string;
}): Promise<void> => {
    const oidcIssuer = await resolveOidcIssuer(webId);
    await putPendingSolidSave({webId, isRenewal, title, projectSb3});
    await login({
        oidcIssuer,
        redirectUrl: `${window.location.origin}${window.location.pathname}`,
        clientName: 'Scratch',
        clientId
    });
};
{% endcode_snippet %}

When the page loads again, the editor checks whether it's coming back from a
login, and if a save was waiting, finishes it:

{% code_snippet lang="ts" path="packages/scratch-gui/src/lib/solid-save.ts" start=167 %}
export const completePendingSolidSave = async (): Promise<CompletedSolidSave | null> => {
    const returningFromLogin = new URLSearchParams(window.location.search).has('state');
    // Restoring the previous session is what lets later saves skip the login.
    const sessionInfo = await handleIncomingRedirect({restorePreviousSession: true});
    if (!returningFromLogin) return null;

    const pending = await takePendingSolidSave();
    if (!pending) return null;

    const {webId, isRenewal, title, projectSb3} = pending;
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
        const url = await writeProject(webId, title, projectSb3);
        return {outcome: {status: 'saved', url}, isRenewal, title, projectSb3};
    } catch (error) {
        log.error(`completePendingSolidSave: failed to write the project for ${webId}`, error);
        return {outcome: {status: 'error', message: errorMessage(error)}, isRenewal, title, projectSb3};
    }
};
{% endcode_snippet %}

### Writing to the Pod

The write itself is short. It finds the user's Pod from their profile,
makes a `scratch/` folder in it if there isn't one, and writes the project's
`.sb3` file there, named after its title:

{% code_snippet lang="ts" path="packages/scratch-gui/src/lib/solid-save.ts" start=78 %}
const writeProject = async (webId: string, title: string, projectSb3: Blob): Promise<string> => {
    const {fetch} = getDefaultSession();
    const [podUrl] = await getPodUrlAll(webId, {fetch});
    if (!podUrl) {
        throw new Error(`No Pod storage (pim:storage) is listed in the profile at ${webId}.`);
    }
    const containerUrl = new URL(`${CONTAINER_NAME}/`, podUrl).href;
    await ensureContainer(containerUrl, fetch);

    const fileUrl = new URL(fileNameForTitle(title), containerUrl).href;
    await overwriteFile(fileUrl, projectSb3, {contentType: SB3_CONTENT_TYPE, fetch});
    return fileUrl;
};
{% endcode_snippet %}

The `fetch` here comes from the Solid session, and adds the user's token to
each request. The Pod server, not Scratch, decides whether the write is
allowed: it accepts it because the logged-in user owns the Pod.

### Saving again, and short-lived sessions

Once someone has logged in, later saves go straight to the Pod with no
dialog, just Scratch's usual "Saving…" and "Project saved." alerts.

The Inrupt library only refreshes an access token if the login that produced it
returned a refresh token, and a session silently restored after a page load
doesn't have one. So when a save finds no session, or the Pod rejects the
token with an HTTP 401, the editor logs in again by itself, using the WebID
from the last successful login, rather than showing the dialog again:

{% code_snippet lang="jsx" path="packages/scratch-gui/src/containers/solid-save-modal.jsx" start=126 %}
        savingSb3
            .then(projectSb3 => saveToSolidPod({title: projectTitle, projectSb3}))
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

## What the demo doesn't do yet {#gaps}

- **No loading.** Projects can be saved to a Pod but not opened from one.
  There's no "Open from your Pod" yet, so the only way to see a saved project
  is with another Solid app, as in the demo.
- **No description or thumbnail.** Each project is saved as a single `.sb3`
  file, with everything needed to open it again. The description and
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
- **Rough edges in the login.** The user types their WebID by hand. Scratch
  now identifies itself with a Client ID Document, but only the demo's local
  development server provides one, and it says little more than the app's
  name. A hosted editor would need its own, published at a public address.
- **Projects are named by title.** Two projects with the same title
  overwrite each other.

{% include mermaid.html %}

<script src="{{ '/assets/js/copy-code.js' | relative_url }}" defer></script>
