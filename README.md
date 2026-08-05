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
_quarto.yml     navigation, site title, footer, theme wiring
theme.scss      all the visual design — colours and fonts at the top
index.qmd       home page
research.qmd    research themes and software
people.qmd      lab members
publications.qmd
join.qmd        recruitment
images/people/  headshots
docs/           generated output — never edit by hand
CNAME           the custom domain
```

## Editing notes

Everything in square brackets is a placeholder to replace.

The mono uppercase section labels come from a custom class:

```markdown
[Recent]{.eyebrow}
```

Adding a person means copying one block in `people.qmd`:

```markdown
::: {.person}
![](images/people/name.jpg)
[[Name]]{.name}
[PhD Student]{.role}
:::
```

Note the two trailing spaces at the end of the name line — that is what makes the
role appear on its own line in Markdown.

To change the palette, edit the six variables at the top of `theme.scss`. The
site uses a single accent colour (`$pine`); changing that one value re-tints
links, section labels, and focus rings together.

Quarto ships a set of ready-made Bootswatch themes if you would rather start
somewhere else — swap `default` for `cosmo`, `litera`, `flatly`, etc. in
`_quarto.yml` and keep `theme.scss` layered on top.

## Adding R output

Any page can run R. Change the extension logic nowhere — just add a chunk:

````markdown
```{r}
#| echo: false
#| fig-width: 7
plot(pressure)
```
````

The figure is rendered at build time and baked into the HTML, so the published
site stays static.
