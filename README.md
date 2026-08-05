# Soomro Lab — site setup

A Quarto website. You write Markdown, run one command, commit, and GitHub serves
it at soomrolab.com. No hosting bill, no build server.

---

## 1. Install Quarto

Download the installer from <https://quarto.org/docs/get-started/>. It is a
single binary and installs like any other app. If you use RStudio, Quarto is
already bundled — but installing the standalone version keeps it current.

Optional, only if you want to run R code inside pages:

```r
install.packages("quarto")
```

Check it worked:

```bash
quarto check
```

## 2. Preview locally

From this folder:

```bash
quarto preview
```

A browser opens and reloads every time you save a `.qmd` file. Leave it running
while you edit. `Ctrl-C` to stop.

## 3. Build the site

```bash
quarto render
```

This writes the finished HTML into `docs/`. That folder is what GitHub publishes,
so it gets committed along with everything else — do not add it to `.gitignore`.

## 4. Put it on GitHub

Create a new **public** repository (Pages is free only on public repos for
personal accounts). Call it whatever you like — `soomrolab` is fine.

```bash
git init
git add .
git commit -m "Initial site"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/soomrolab.git
git push -u origin main
```

Then in the repo: **Settings → Pages**

- Source: *Deploy from a branch*
- Branch: `main`, folder: `/docs`
- Save

Give it a minute, then check `https://YOUR-USERNAME.github.io/soomrolab/`.

One-time housekeeping — GitHub runs Jekyll over the folder unless you tell it not
to:

```bash
touch docs/.nojekyll
git add docs/.nojekyll && git commit -m "Disable Jekyll" && git push
```

## 5. Point soomrolab.com at it

**In GitHub first.** Settings → Pages → Custom domain → type `soomrolab.com` →
Save. Do this before touching DNS; it stops anyone else claiming the domain on
Pages.

**Then in GoDaddy.** Go to your domain → DNS → Manage Zones / DNS Records.

Delete GoDaddy's default parked `A` record for `@`, and turn off any domain
forwarding it set up automatically. Then add:

| Type  | Name | Value                     | TTL    |
|-------|------|---------------------------|--------|
| A     | @    | `185.199.108.153`         | 1 hour |
| A     | @    | `185.199.109.153`         | 1 hour |
| A     | @    | `185.199.110.153`         | 1 hour |
| A     | @    | `185.199.111.153`         | 1 hour |
| CNAME | www  | `YOUR-USERNAME.github.io` | 1 hour |

Yes, four separate A records with the same name — that is correct and expected.
If there is already a `www` CNAME pointing to `@`, edit it rather than adding a
second one.

Optionally add IPv6 as `AAAA` records on `@`: `2606:50c0:8000::153`,
`2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`.

**Then wait.** Ten minutes is typical, up to a day is possible. Once GitHub stops
complaining about the domain, go back to Settings → Pages and tick **Enforce
HTTPS**. If the checkbox is greyed out, the certificate has not been issued yet —
come back in an hour. Removing and re-adding the custom domain forces a retry.

The `CNAME` file in this folder is listed under `resources:` in `_quarto.yml` so
every render copies it into `docs/` and the domain survives rebuilds.

## 6. Day-to-day

```bash
# edit a .qmd file, then:
quarto render
git add . && git commit -m "Add new preprint" && git push
```

Live within a minute or two.

---

## Where things live

```
_content/            <- everything you edit
  home.yml             hero, intro, which blocks show on the home page
  research.yml         the four research themes
  software.yml         tools and internal pipelines
  about.yml            Tayab's bio, positions, education, awards, press
  join.yml             recruitment and collaboration
  people.yml           team and collaborators
  publications.yml     papers and the patent
  presentations.yml    posters and invited talks
  news.yml             one-line updates
  settings.yml         page titles, section headings, author bolding

blog/posts/          <- drop new posts here
  _how-to-write-posts.qmd    reference file; never publishes

images/
  people/              headshots (PI entry expects soomro.jpg)
  logo.svg             navbar mark
  favicon.png
  og-image.png         social sharing card

_quarto.yml          site title, navigation, footer, social links
theme.scss           colours and fonts
_helpers.R           machinery — turns the YAML into pages
*.qmd                machinery — you should not need to open these
docs/                generated output — never edit by hand
CNAME                the custom domain
```

The `.qmd` files are short templates that read the YAML. If you find
yourself editing one, that is a sign the YAML is missing a field.

## Pages

| Page | Source |
| --- | --- |
| Home | `_content/home.yml` + news + recent posts |
| Research | `_content/research.yml` |
| Software | `_content/software.yml` |
| Team | `_content/people.yml` |
| Publications | `_content/publications.yml` + `presentations.yml` |
| Notes (blog) | `blog/posts/` |
| Work with us | `_content/join.yml` |
| Tayab Soomro | `_content/about.yml` |
| News archive | `_content/news.yml` |

## Editing content

Every field is Markdown, so links, `*emphasis*` and `[phrase]{.accent}` (the
accent underline) work anywhere.

**Home page** — the `show: true/false` flags turn the news, blog and contact
blocks on and off; `count:` controls how many items each shows.

**News** — add a block to `_content/news.yml`:

```yaml
- date: 2026-08-05
  text: "Our paper on [topic] is out in [*Nature*](https://example.com)."
```

Order in the file does not matter; items sort by date, newest first.

**People** — add a block to `_content/people.yml`:

```yaml
- group: member
  name: "Jane Doe"
  role: "PhD Student"
  photo: images/people/doe.jpg
  links:
    Email: "mailto:doe@university.edu"
```

`group` is `pi`, `member`, `alumni` or `collaborator`. Photos are optional —
leave one out and a plain tile appears, so you can add someone before you have
a picture of them. When a student finishes, change `group` to `alumni` and add
a `now:` line; they move out of the photo grid on their own.

**Publications** — add a block to `_content/publications.yml`:

```yaml
- year: 2026
  authors: "Doe J, Soomro T"
  title: "Title of the paper."
  venue: "Journal Name, 14(2), 200-215."
  links:
    PDF: "https://..."
    Code: "https://github.com/..."
```

Year headings generate themselves. Your name is bolded automatically — the
string matched is under `publications: highlight:` in `settings.yml`. Posters
and talks live in `presentations.yml` and use `year` + `text`.

**Software** — `_content/software.yml`. Two lists, `tools` and `pipelines`,
both shaped `name` / `tagline` / `status` / `body` / `links`. The `status`
string renders as the small green chip.

**Research, Join, About** — lists of `title` + `body` sections, so adding a
section means adding a block. Use `|` for multi-paragraph bodies:

```yaml
- title: "Theme five"
  body: |
    First paragraph.

    Second paragraph.
```

`about.yml` also holds `positions` and `education` (shaped `period` / `role` /
`org` / `body`), plus `awards`, `ventures` and `media` lists.

## Writing blog posts

Drop a `.qmd` file into `blog/posts/`. It needs two fields:

```yaml
---
title: "Your post title"
date: 2026-08-05
description: "One line that shows up in the listing."
categories: [breeding informatics, nanopore]
---

Body in Markdown.
```

The blog page picks it up automatically, sorts by date, generates the RSS feed,
and turns `categories` into filter buttons. The three most recent posts also
appear on the home page. Files starting with `_` never publish — that is how
`_how-to-write-posts.qmd` stays out of the site.

Then, as always:

```bash
quarto render
git add . && git commit -m "Add August post" && git push
```

## Changing the chrome

Site title, navigation, footer, favicon and the social card are in
`_quarto.yml`. Adding a nav item is one entry under `navbar: left:`.

To change the palette, edit the six variables at the top of `theme.scss`. The
site uses a single accent colour (`$pine`); changing that one value re-tints
links, section labels, the software status chips, blockquote rules and focus
rings together. The logo and social card are separate files in `images/` and
would need regenerating by hand.

## If something breaks

**A page renders empty or a block is missing.** The `.yml` file has a syntax
error — usually a colon or a `#` inside an unquoted string. Wrap the value in
double quotes. Indentation must be spaces, never tabs.

**`Missing data file: _content/x.yml`.** A file was renamed or deleted; the
page renders without that block rather than failing.

**Content appears as literal `:::` on the page.** A chunk lost its
`#| output: asis` option.

**`there is no package called 'yaml'`.** Run `install.packages("yaml")`. It
normally arrives with knitr, so this is rare.

**A new blog post does not appear.** It is missing `title:` or `date:` in the
front matter, or the filename starts with an underscore.
