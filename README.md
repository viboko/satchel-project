# Satchel

The website explaining the Satchel project — a prototype that lets a
child's Scratch projects be saved to their own personal [Solid](https://solidproject.org/)
Pod, with sharing decided by the child and their guardian together instead
of Scratch's all-or-nothing switch. Built with [Jekyll](https://jekyllrb.com).

Live at <https://satchel.viboko.dev>.

Page content lives in `pages/`; each page sets its own `permalink`.

Blog posts live in `_posts/`, named `YYYY-MM-DD-slug.md`, and are published
at `/updates/YYYY-MM-DD-slug/`. They're listed newest first at `/blog/`
(`blog/index.html`, paginated by `jekyll-paginate`), and the three latest
also appear on the home page.

## Running locally

Install dependencies:

```bash
just install
```

Then start the dev server:

```bash
just dev
```

The site will be available at <http://localhost:4002>.

`just dev`'s server (Jekyll's WEBrick) can't serve video reliably: in
Chrome a video stalls partway through, or fails to seek. To check a page
with video, run `just preview` instead. It builds the site and serves it
with `http-server` at <http://localhost:4003>, which handles video the way
GitHub Pages does, but without live reload.

## Checks

The `ci` GitHub Actions workflow runs three independent checks on every push
and pull request: `just lint`, `just check-accessibility`, and
`just check-security`.

### Linting

```bash
just lint
```

Lints YAML (`eslint-plugin-yml`), Markdown (`markdownlint`), SCSS
(`stylelint`), JavaScript (`eslint`), the built HTML (`html-proofer`,
checking internal links/images/anchors), and SEO basics (`robots.txt`,
`sitemap.xml`, absolute OG/canonical URLs).

### Accessibility

```bash
just check-accessibility
```

Checks accessibility with `pa11y-ci` (WCAG2AA, against every page in the
sitemap) and Lighthouse. Both build the site and serve it locally to run
against.

If `just check-pa11y` fails locally with a Chrome `dlopen` error, the
Chrome build that `pa11y-ci`'s Puppeteer dependency downloaded is corrupt -
delete `~/.cache/puppeteer` and re-run `just install`, or set
`PUPPETEER_EXECUTABLE_PATH` to an existing Chrome install.

### Security

```bash
just check-security
```

Checks dependencies for known vulnerabilities with `bundler-audit`
(Ruby gems, against the [ruby-advisory-db](https://github.com/rubysec/ruby-advisory-db))
and [`osv-scanner`](https://google.github.io/osv-scanner/) (Ruby and npm
lockfiles, against the [OSV database](https://osv.dev)). `osv-scanner`
isn't managed by `just install` - install it separately, e.g.
`brew install osv-scanner`.

Vulnerabilities that don't apply (e.g. dev-only tooling with no fix
available) are suppressed with a reason in [`osv-scanner.toml`](osv-scanner.toml)
rather than silently ignored.

Separately, [Dependabot](.github/dependabot.yml) opens a PR weekly for any
outdated Ruby gem, npm package, or GitHub Action.
