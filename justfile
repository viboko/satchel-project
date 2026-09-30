# List available recipes
default:
	@just --list

# Install dependencies
install:
	bundle install
	npm install

# Run the site locally with live reload
dev:
	bundle exec jekyll serve --host 0.0.0.0 --port 4002

# Build the production site
build:
	bundle exec jekyll build

# Lint markdown
lint-markdown:
	npx markdownlint-cli "**/*.md" --ignore node_modules --ignore _site --ignore vendor

# Lint scss
lint-scss:
	npx stylelint "_sass/**/*.scss" "assets/css/**/*.scss"

# Lint js and yaml
lint-js:
	npx eslint .

# Lint the built html
lint-html: build
	LANG=en_US.UTF-8 bundle exec htmlproofer ./_site --disable-external

# Check robots.txt, sitemap.xml, and that OG/canonical URLs are absolute
lint-seo: build
	#!/usr/bin/env bash
	set -euo pipefail
	test -f _site/robots.txt || { echo "missing _site/robots.txt"; exit 1; }
	test -f _site/sitemap.xml || { echo "missing _site/sitemap.xml"; exit 1; }
	ruby -rrexml/document -e "REXML::Document.new(File.read('_site/sitemap.xml'))"
	while IFS= read -r f; do
		grep -oE 'property="og:url" content="[^"]*"' "$f" | grep -q 'content="https://' \
			|| { echo "$f: og:url is missing or not an absolute https URL"; exit 1; }
		grep -oE 'rel="canonical" href="[^"]*"' "$f" | grep -q 'href="https://' \
			|| { echo "$f: canonical link is missing or not an absolute https URL"; exit 1; }
		if grep -q 'property="og:image"' "$f"; then
			grep -oE 'property="og:image" content="[^"]*"' "$f" | grep -q 'content="https://' \
				|| { echo "$f: og:image is not an absolute https URL"; exit 1; }
		fi
	done < <(find _site -name "*.html")
	echo "SEO checks passed"

# Check accessibility (WCAG2AA) with pa11y against every page in the sitemap
check-pa11y: build
	#!/usr/bin/env bash
	set -euo pipefail
	npx http-server _site -p 4001 -e html -s >/dev/null 2>&1 &
	server_pid=$!
	trap 'kill "$server_pid" 2>/dev/null' EXIT
	for i in $(seq 1 30); do
		curl -sf http://localhost:4001/sitemap.xml >/dev/null && break
		sleep 1
	done
	site_url=$(grep -E '^url:' _config.yml | sed -E 's/^url:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/')
	npx pa11y-ci \
		--sitemap http://localhost:4001/sitemap.xml \
		--sitemap-find "$site_url" --sitemap-replace http://localhost:4001 \
		--sitemap-exclude '\.pdf$'

# Check accessibility with Lighthouse against every page of the built site
check-lighthouse: build
	npx lhci autorun

# Check accessibility (pa11y and Lighthouse) against every page of the built site
check-accessibility: check-pa11y check-lighthouse

# Check Ruby gems for known vulnerabilities against the ruby-advisory-db
check-bundler-audit:
	bundle exec bundle-audit check --update

# Check npm and Ruby dependencies for known vulnerabilities against the OSV database
check-osv-scanner:
	# vendor/ is CI's installed gem tree (bundler-cache); Gemfile.lock already
	# covers its gem versions, and osv-scanner's ignore config can't suppress
	# the git-commit-based matches it makes against vendored native C sources
	osv-scanner scan source -r --experimental-exclude vendor .

# Check dependencies for known vulnerabilities
check-security: check-bundler-audit check-osv-scanner

# Lint yaml, markdown, scss and js source files, then check the built html
lint: lint-markdown lint-scss lint-js lint-html lint-seo

# Remove build artifacts and caches
clean:
	rm -rf _site .jekyll-cache .lighthouseci
