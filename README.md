# Tag Designs Documentation

This repository contains the Hugo documentation site for the tag designs
project. The Hugo site itself lives in `docs/`; the repository root has a small
`CMakeLists.txt` so the project can also be configured from the top level.

The site uses Hugo Modules for Docsy and Hugo Simple Cite, so the first build
needs network access to download module dependencies into Hugo's cache.

## Prerequisites

Required for a normal site build:

- Git
- CMake 3.10 or newer
- Go 1.22 or newer
- Node.js 22 LTS or newer with npm
- Hugo Extended 0.155.3 or newer

Optional, only needed when regenerating the TikZ-derived SVG images:

- A LaTeX distribution with `pdflatex`
- `pdf2svg`

Optional, only needed for the `sync-gh-pages` CMake target:

- `rsync`

After installing Hugo, check that you have a recent extended build:

```sh
hugo version
```

After installing Node.js, install the local PostCSS toolchain:

```sh
cd docs
npm ci
```

The PostCSS executable is installed locally at `docs/node_modules/.bin/postcss`.
Use the npm scripts below, or the CMake `docs` target, so that local executable
is placed on `PATH` when Hugo runs.

## Installing Tools

### macOS / OS X

With Homebrew:

```sh
brew install cmake git go node hugo pdf2svg rsync
brew install --cask mactex-no-gui
```

If you do not need to regenerate the TikZ images, you can skip `pdf2svg` and
MacTeX.

### Linux

On Debian or Ubuntu, install most tools with apt:

```sh
sudo apt update
sudo apt install cmake git golang-go rsync \
  texlive-latex-base texlive-latex-extra texlive-fonts-recommended pdf2svg
```

Install Node.js 22 LTS or newer with `nvm`, NodeSource, or the official
installer. The `nodejs` package in some Linux distributions is still Node 18;
with Hugo 0.161 and newer that fails during PostCSS with
`/usr/bin/node: bad option: --permission`.

Install Hugo Extended from the Hugo release page, Homebrew for Linux, Snap, or
another source that provides a current extended build. The Hugo package in some
Linux distributions can be too old or not extended.

### Windows

Install the required tools with a package manager or the official installers.
For example, with Chocolatey in an elevated PowerShell:

```powershell
choco install cmake git golang nodejs-lts hugo-extended
```

For optional image regeneration, install MiKTeX or TeX Live for `pdflatex`.
Install `pdf2svg` through MSYS2 or another Windows package source. If you want
to use `sync-gh-pages`, run the build from Git Bash/MSYS2 with `rsync`
available; otherwise use the direct Hugo or GitHub Actions publishing flow.

## Local Development

Start a local development server:

```sh
cd docs
npm ci
npm run server
```

Then open the URL printed by Hugo, usually `http://localhost:1313/`.

Build a local static copy directly with Hugo:

```sh
cd docs
npm ci
npm run build -- --baseURL "/"
```

The generated site is written to `docs/public/`.

Serve that generated site from the `public/` directory when previewing it:

```sh
cd docs/public
python3 -m http.server 8000
```

Then open `http://localhost:8000/`. Opening `index.html` directly from the
filesystem can leave root-relative CSS and JavaScript links unresolved.

For GitHub Pages, use the Pages base URL instead:

```sh
cd docs
npm run build -- --baseURL "https://tag-designs.github.io/docs/"
```

If you run `hugo` directly instead of through npm, make sure the local npm
binary directory is on `PATH`:

```sh
cd docs
PATH="$(pwd)/node_modules/.bin:$PATH" hugo --gc --minify --baseURL "/"
```

## CMake Build

Configure from the repository root:

```sh
cmake -S . -B build
```

Run `npm ci` in `docs/` before building the CMake `docs` target. CMake runs
Hugo from the `docs/` directory and adds `docs/node_modules/.bin` to `PATH`, so
Hugo can find the local PostCSS executable and `docs/postcss.config.js`.

Build the Hugo site:

```sh
cmake --build build --target docs
```

The generated site is written to `build/docs/public/`.

For a GitHub Pages build, configure with the Pages base URL:

```sh
cmake -S . -B build-pages -DHUGO_BASEURL="https://tag-designs.github.io/docs/"
cmake --build build-pages --target docs
```

Regenerate TikZ SVG images when needed:

```sh
cmake --build build --target images-svg
```

The SVG files are copied into `docs/static/images-svg/`.

To mirror the generated site into a local checkout of a Pages branch, configure
the destination and run the explicit sync target:

```sh
cmake -S . -B build -DGH_PAGES_DIR=/path/to/gh-pages
cmake --build build --target sync-gh-pages
```

## Hosting On GitHub Pages

GitHub Pages can publish static files from a branch, but this site has a Hugo
build step, Node/PostCSS dependencies, and Hugo Modules. The most reliable
setup is to publish with GitHub Actions.

1. Push this repository to GitHub.
2. In the repository settings, go to **Pages**.
3. Under **Build and deployment**, set **Source** to **GitHub Actions**.
4. Use the workflow in `.github/workflows/pages.yml`.

Example workflow:

```yaml
name: Build and deploy Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      GO_VERSION: "1.22"
      HUGO_VERSION: "0.161.1"
      NODE_VERSION: "22"
      HUGO_CACHEDIR: "${{ runner.temp }}/hugo_cache"
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: "${{ env.GO_VERSION }}"

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "${{ env.NODE_VERSION }}"
          cache: npm
          cache-dependency-path: docs/package-lock.json

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v5

      - name: Install Hugo Extended
        run: |
          curl -sLJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
          mkdir "${RUNNER_TEMP}/hugo"
          tar -C "${RUNNER_TEMP}/hugo" -xf "hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
          echo "${RUNNER_TEMP}/hugo" >> "${GITHUB_PATH}"

      - name: Install Node dependencies
        working-directory: docs
        run: npm ci

      - name: Build
        working-directory: docs
        run: npm run build -- --baseURL "${{ steps.pages.outputs.base_url }}/"

      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v4
        with:
          path: docs/public

  deploy:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: "${{ steps.deployment.outputs.page_url }}"
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

For a project site, the published URL will usually be
`https://OWNER.github.io/REPOSITORY/`. For a user or organization site named
`OWNER.github.io`, use `https://OWNER.github.io/`.
