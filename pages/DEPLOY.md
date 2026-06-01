---
title: Deploying these docs
---

# Deploying the docs to GitHub Pages

[← Docs home](index.md)

This `pages/` folder is a self-contained [Jekyll](https://jekyllrb.com/) site
(Markdown + `_config.yml`, theme `jekyll-theme-cayman`). There are three ways to
publish it; pick one.

## Approach 1 — GitHub Actions (recommended)

The repo ships `.github/workflows/pages.yml`, which builds `pages/` with Jekyll
and deploys it on every push to `master`. The `configure-pages` step uses
`enablement: true`, so it **turns Pages on automatically** (build type: GitHub
Actions) — no manual settings step needed.

1. Push the `pages/` folder and the workflow to `master`.
2. Watch the **Actions** tab; on success the site goes live at
   `https://<user>.github.io/<repo>/` (and the URL is shown on the `deploy`
   job).

You can also trigger it manually from the **Actions** tab
(*workflow_dispatch*). If auto-enable is blocked by org policy, enable it once
under **Settings → Pages → Source: GitHub Actions** and re-run.

Why this one: it publishes an arbitrary subfolder (`pages/`) without moving
files, and it's the modern GitHub-recommended flow.

## Approach 2 — "Deploy from a branch", `/docs` folder

GitHub Pages can serve from the repo root or a `/docs` folder on a branch — but
**not** an arbitrary `pages/` folder. To use this no-Actions route, publish the
site under `docs/`:

```bash
# one-time: make docs/ mirror the site source
git mv pages docs        # or: cp -R pages docs
git commit -m "Publish docs site under /docs"
git push
```

Then **Settings → Pages → Source: Deploy from a branch → Branch: `master`,
Folder: `/docs`**. (Update the internal links if you rename the folder.)

## Approach 3 — `gh-pages` branch

Build locally or in CI and push the generated `_site/` to a `gh-pages` branch:

```bash
cd pages
bundle exec jekyll build           # produces _site/
# publish _site/ to the gh-pages branch (e.g. with peaceiris/actions-gh-pages)
```

Then **Settings → Pages → Source: Deploy from a branch → Branch: `gh-pages`,
Folder: `/`**.

## Preview locally

```bash
cd pages
bundle init
echo 'gem "github-pages", group: :jekyll_plugins' >> Gemfile
bundle install
bundle exec jekyll serve   # http://localhost:4000
```

## Custom domain

Add a `CNAME` file (containing your domain) to the published folder, and set the
domain under **Settings → Pages → Custom domain**.

## Notes

- The site uses only GitHub-Pages-supported plugins (the `github-pages` gem), so
  no extra configuration is required for Approach 1.
- Internal links are relative (`guides/swift.md` etc.), so they work whether the
  site is served from `/`, `/docs`, or a project subpath.
