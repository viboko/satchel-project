---
title: Structuring the code
description: >-
  How Satchel's code is split between three repositories, why, and how each
  part is versioned: a small set of hooks in a fork of Scratch's editor, a
  separate app that uses them, and Satchel itself, with nothing about Scratch
  in it.
---

The ODI support period starts today, so this is a good moment to get the
foundations right. The [first prototype](/blog/2026-10-25-initial-investigations/)
proved that a Scratch project can be saved to a Solid Pod, but all of its
code lived inside a fork of Scratch's editor. Before building anything
else, I want the code split into the right pieces, so that each one can
change, be licensed and be released on its own.

<!-- The diagram is HTML, or looks like it to markdownlint. -->
<!-- markdownlint-disable MD033 -->

## What "Satchel" means

I've been loose with the name so far, so first, a definition:

- **Satchel** is the general part: the code that lets a child's work be
  saved to their own Solid Pod, and shared only when the child and their
  guardian agree. Nothing in it is about Scratch.
- **satchel-blocks** is the first app built on Satchel: a block-based
  coding editor, based on Scratch's open-source editor, that saves to a Pod.
  It's the use case I'll be developing with the ODI's support.

Another tool, say for art, music or writing, could use Satchel the same way,
with an app of its own.

## Three repositories

<div class="mermaid">
flowchart TB
    accTitle: How Satchel's repositories and packages depend on each other
    accDescr: Three repositories. satchel-blocks, under AGPL-3.0, is the app; it holds the e2e tests and depends on two packages. The first is viboko/scratch-gui, built from the fork of Scratch's editor, also AGPL-3.0, which depends on Scratch's own unmodified packages, such as scratch-vm and scratch-render, from npm. The fork merges changes from scratchfoundation/scratch-editor, and offers its hooks back upstream. The second is satchel-core, from the satchel repository, under MIT. The satchel repository also holds the dashboard and the agent, which both depend on core, and the vocabulary, under CC BY 4.0, which core, the dashboard and the agent all use.

    subgraph upstream["scratchfoundation/scratch-editor"]
        upstreamGui["scratch-gui"]
    end

    subgraph fork["viboko/scratch-editor · AGPL-3.0"]
        gui["scratch-gui, with hooks"]
        unchanged["scratch-vm, scratch-render, … (unchanged)"]
    end

    subgraph blocks["viboko/satchel-blocks · AGPL-3.0"]
        app["the app"]
        e2e["e2e tests"]
    end

    subgraph satchel["viboko/satchel · MIT"]
        core["core"]
        dashboard["dashboard"]
        agent["agent"]
        vocabulary["vocabulary · CC BY 4.0"]
    end

    upstream -- "merged into the fork" --> fork
    gui -. "hooks offered upstream" .-> upstreamGui
    app -- "@viboko/scratch-gui" --> gui
    gui -- "@scratch/* from npm" --> unchanged
    app -- "@viboko/satchel-core" --> core
    e2e -- "drives" --> app
    dashboard --> core
    agent --> core
    core --> vocabulary
    dashboard --> vocabulary
    agent --> vocabulary
</div>

### viboko/scratch-editor: a fork, kept as small as possible

[viboko/scratch-editor](https://github.com/viboko/scratch-editor){:target="_blank" rel="noopener"}
is a fork of
[scratchfoundation/scratch-editor](https://github.com/scratchfoundation/scratch-editor){:target="_blank" rel="noopener"},
the monorepo behind Scratch's editor. It holds several packages:
`scratch-gui` (the editor's interface), `scratch-vm` (which runs projects),
`scratch-render`, `scratch-paint`, `scratch-storage` and a few more.

Only `scratch-gui` changes, and only to add a few general-purpose
**hooks**: places where an app that embeds the editor can supply its own
behaviour or branding. The fork knows nothing about Solid or Satchel.

Keeping it that small is the whole point. Scratch's editor changes all the
time, and every change in the fork is something that can conflict when
those updates are merged in. A fork that only adds a few hooks stays easy to
keep up to date. Each hook is also something any app that embeds the editor
might want, so the aim is to offer every one of them upstream. If Scratch
accepts them all, the fork can go away entirely.

### viboko/satchel-blocks: the app

satchel-blocks is the app itself. It doesn't modify the editor: it
embeds it, the way the Scratch website does, and uses the hooks to plug in
saving to a Pod, the "Save to your Solid Pod" dialog, and its own name and
look.

Its end-to-end tests live here too. They drive the app in a real browser
against a local Solid server, and they test the Scratch use case, so they
belong with it, not with Satchel.

### viboko/satchel: everything that isn't about Scratch

The `satchel` repository holds four packages that share one data model:

- **core**: saving and loading a piece of work in a Pod, and later the
  share requests, decisions, guardian links, and the rule that decides
  whether a share is approved. This is the package other tools would reuse.
- **dashboard**: where a child and their guardian request, approve and
  revoke shares.
- **agent**: the small service that carries out those decisions in the
  Pod.
- **vocabulary**: the published terms for guardianship and consent.

The dashboard and agent aren't specific to Scratch either, so they live
with core, not with the app. There's no separate e2e package for now:
each package has its own tests, and the end-to-end tests that go through the
whole journey (a child saving, a guardian approving, the agent granting
access) can live in satchel-blocks, which is where that journey starts.

The repository will be public soon, but isn't yet.

## Licences

| Repository or package | Licence | Why |
| --- | --- | --- |
| viboko/scratch-editor | AGPL-3.0 | It's Scratch's code, under Scratch's licence. |
| viboko/satchel-blocks | AGPL-3.0 | It bundles the editor, so the app as a whole is under Scratch's licence. |
| satchel: core, dashboard, agent | MIT | None of it uses Scratch's code, so it can be reused anywhere. |
| satchel: vocabulary | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/){:target="_blank" rel="noopener"} | It's a published vocabulary, not software. |

Keeping the split clean matters most for core: it must never import
anything from Scratch, or it couldn't stay MIT-licensed.

## The changes to scratch-editor

Scratch's editor already lets an embedding app do a lot. It can get hold
of the project's virtual machine (`onVmInit`), which is enough to save the
whole project as an `.sb3` file and to load one back after the Solid login.
It can set and follow the project's title, replace the logo (`logo` and
`onClickLogo`), and say where the media library's files come from
([`GUIStorage`](https://github.com/scratchfoundation/scratch-editor/blob/develop/packages/scratch-gui/src/gui-config.ts){:target="_blank" rel="noopener"}).

What's missing is:

1. **Saving, handled by the app.** File > Save now, and Ctrl/Cmd+S, should
   be able to call the embedding app, instead of saving to Scratch's own
   project server.
2. **A different default project.** The project a new editor opens with is
   built into the editor.
3. **A different media library.** The sprites, costumes, backdrops, sounds
   and tutorials offered in the libraries are built in too.
4. **A different accent colour.** The editor's purple is fixed when its CSS
   is built, so an app can't change it.
5. **Possibly, different interface text**, where a message names Scratch.

Each one will be a separate, small pull request on the fork, so each can be
offered upstream on its own.

## Versioning

Everything new starts at **0.1.0**: satchel-blocks, and each package in the
satchel repository. Until 1.0.0, a breaking change bumps the middle number.
Each package in satchel is versioned and released on its own: the
vocabulary will change far less often than the dashboard, and a version of
the vocabulary that says nothing new shouldn't appear just because the
dashboard changed.

The forked `scratch-gui` is different. It's Scratch's package plus a few
hooks, so starting it at 0.1.0 would hide the one thing its version needs
to say: which version of Scratch it's based on. So it keeps upstream's
version and adds a suffix:

| Version | Meaning |
| --- | --- |
| `15.3.0-satchel.1` | Scratch's 15.3.0, with the first release of the hooks |
| `15.3.0-satchel.2` | The same Scratch, with a change to the hooks |
| `15.4.0-satchel.1` | After merging Scratch's 15.4.0 into the fork |

It's published under its own name, `@viboko/scratch-gui`, so it can't be
mistaken for Scratch's. One quirk comes with the suffix: under
[semantic versioning](https://semver.org/#spec-item-9){:target="_blank" rel="noopener"},
`15.3.0-satchel.1` counts as earlier than `15.3.0`, so version ranges like
`^15.3.0` won't match it. satchel-blocks names the exact version it uses,
which is what Scratch's own packages do with each other anyway.

The other packages in the fork, such as `scratch-vm`, aren't changed, so
they aren't published from it at all. satchel-blocks gets them from npm,
as Scratch publishes them, at the versions the forked `scratch-gui` names.

## Publishing

Each repository needs the others as packages, and npm can't install a
package from a folder inside a git repository, which is where `scratch-gui`
and core both live. So both are published:

- **`@viboko/scratch-gui` goes to npm.** It's public, AGPL-licensed code
  anyway.
- **`@viboko/satchel-core` goes to [GitHub Packages](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-npm-registry){:target="_blank" rel="noopener"}
  for now**, privately, while the satchel repository is private. Once it's
  public, it moves to npm, since GitHub Packages asks for a token even to
  install a public package.

## Scratch's trademarks

Scratch's code is open source, but its name and characters aren't.
Scratch's [TRADEMARK](https://github.com/scratchfoundation/scratch-editor/blob/develop/TRADEMARK){:target="_blank" rel="noopener"}
notice says that the Scratch name and logo, the Scratch Cat, and the
characters Gobo, Pico, Nano, Tera and Giga belong to the Scratch
Foundation, and may not be used "to endorse or promote products derived
from this software without specific prior written permission".

satchel-blocks is a product derived from Scratch's code, so:

- **It doesn't use the Scratch name as its own.** That's why it's
  satchel-blocks, not something with "Scratch" in it. It can still
  describe what it is, plainly: it's built on Scratch's open-source editor,
  and opens and saves Scratch's `.sb3` project files.
- **It replaces the logo** in the editor's menu bar
  ([Scratch's logo](https://github.com/scratchfoundation/scratch-editor/blob/develop/packages/scratch-gui/src/components/menu-bar/scratch-logo.svg){:target="_blank" rel="noopener"}).
- **It opens with its own default project**, not the
  [Scratch Cat](https://github.com/scratchfoundation/scratch-editor/blob/develop/packages/scratch-gui/src/lib/default-project/bcf454acf82e4504149f7ffe07081dbc.svg){:target="_blank" rel="noopener"},
  which is the second hook above.
- **Its media library leaves out the Scratch characters**: the
  [Scratch Cat](https://en.scratch-wiki.info/wiki/Scratch_Cat){:target="_blank" rel="noopener"},
  [Gobo](https://en.scratch-wiki.info/wiki/Gobo){:target="_blank" rel="noopener"},
  [Pico](https://en.scratch-wiki.info/wiki/Pico){:target="_blank" rel="noopener"},
  [Nano](https://en.scratch-wiki.info/wiki/Nano){:target="_blank" rel="noopener"},
  [Tera](https://en.scratch-wiki.info/wiki/Tera){:target="_blank" rel="noopener"}
  and [Giga](https://en.scratch-wiki.info/wiki/Giga){:target="_blank" rel="noopener"}
  (all links to the Scratch Wiki), and doesn't load its media from Scratch's
  servers. That's the third hook.
- **It says that it isn't affiliated with Scratch.**
  [TurboWarp](https://turbowarp.org/){:target="_blank" rel="noopener"},
  another editor built on Scratch's code, does the same.

It may also get a colour of its own, which is the fourth hook. Scratch's
purple isn't a trademark, but it's a large part of what makes the editor
look like Scratch, and a different colour helps make clear that
satchel-blocks is something else.

None of this depends on asking the Scratch Foundation for permission. I may
still ask, but satchel-blocks should work, and could be released, without
it.

## What happens to the code so far

- The first version of core, pulled out of the prototype, becomes the
  `core` package of the satchel repository, at 0.1.0.
- The Solid code in the fork is replaced by the first hook, for saving,
  and moves into satchel-blocks.
- The end-to-end tests and the demo move into satchel-blocks.

Then the first goal is the same as before: a child saving a project to
their Pod, but this time from satchel-blocks, with only the hooks left in
the fork.

{% include mermaid.html %}
