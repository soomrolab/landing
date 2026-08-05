# ─────────────────────────────────────────────────────────────────
# Turns the YAML files in _content/ into page content.
#
# You should not need to open this file. Everything you edit lives
# in _content/*.yml and blog/posts/.
#
# Only dependency is `yaml`, which ships with knitr.
# ─────────────────────────────────────────────────────────────────

DATA_DIR <- "_content"

`%||%` <- function(a, b) {
  if (is.null(a) || (is.character(a) && length(a) == 1 && !nzchar(a))) b else a
}

read_data <- function(file) {
  path <- if (file.exists(file)) file else file.path(DATA_DIR, file)
  if (!file.exists(path)) {
    warning("Missing data file: ", path, call. = FALSE)
    return(list())
  }
  x <- yaml::read_yaml(path)
  if (is.null(x)) list() else x
}

# Print one or more Markdown blocks, each as its own paragraph.
emit <- function(x) {
  if (is.null(x) || !length(x)) return(invisible(NULL))
  for (chunk in x) cat(chunk, "\n\n", sep = "")
  invisible(NULL)
}

# The small mono uppercase label: [Recent]{.eyebrow}
eyebrow <- function(label) {
  if (is.null(label) || !nzchar(label)) return(invisible(NULL))
  cat("[", label, "]{.eyebrow}\n\n", sep = "")
}

rule <- function() cat("---\n\n")

# A named list of links rendered as "PDF · Code · Data"
link_row <- function(links) {
  if (is.null(links) || !length(links)) return("")
  paste(
    vapply(names(links), function(k) sprintf("[%s](%s)", k, links[[k]]), character(1)),
    collapse = " &middot; "
  )
}

# ── Generic titled sections ──────────────────────────────────────
# For research themes, join-page sections, anything shaped
# { title: ..., body: ... }
sections_block <- function(sections, level = 2) {
  if (is.null(sections) || !length(sections)) return(invisible(NULL))
  hashes <- strrep("#", level)
  for (s in sections) {
    if (!is.null(s$title)) cat(hashes, " ", s$title, "\n\n", sep = "")
    emit(s$body)
    row <- link_row(s$links)
    if (nzchar(row)) cat("[", row, "]{.subtle}\n\n", sep = "")
  }
  invisible(NULL)
}

# ── Shaded callout panel ─────────────────────────────────────────
panel_block <- function(panel) {
  if (is.null(panel) || !length(panel)) return(invisible(NULL))
  cat("::: {.panel}\n\n")
  if (!is.null(panel$title)) cat("**", panel$title, "**\n\n", sep = "")
  emit(panel$body)
  cat(":::\n\n")
}

# ── News ─────────────────────────────────────────────────────────
news_block <- function(file = "news.yml", n = Inf) {
  items <- read_data(file)
  if (!length(items)) return(invisible(NULL))

  dates <- as.Date(vapply(items, function(x) as.character(x$date), character(1)))
  ord   <- order(dates, decreasing = TRUE)
  items <- items[ord]
  dates <- dates[ord]

  cat("::: {.news}\n\n")
  for (i in seq_len(min(n, length(items)))) {
    cat("::: {.item}\n\n")
    cat("[", format(dates[i], "%b %Y"), "]{.date}\n\n", sep = "")
    cat(items[[i]]$text, "\n\n", sep = "")
    cat(":::\n\n")
  }
  cat(":::\n\n")
}

# ── Blog posts ───────────────────────────────────────────────────
# Reads the YAML front matter of every file in blog/posts/ so the
# home page can list recent posts. The Blog page itself uses
# Quarto's native listing, which also generates the RSS feed.
read_front_matter <- function(path) {
  lines  <- readLines(path, warn = FALSE)
  fences <- which(trimws(lines) == "---")
  if (length(fences) < 2 || fences[1] != 1) return(list())
  block <- lines[(fences[1] + 1):(fences[2] - 1)]
  out <- tryCatch(yaml::yaml.load(paste(block, collapse = "\n")),
                  error = function(e) NULL)
  if (is.null(out)) list() else out
}

list_posts <- function(dir = "blog/posts") {
  if (!dir.exists(dir)) return(list())
  files <- list.files(dir, pattern = "[.](qmd|md)$", full.names = TRUE)
  files <- files[!startsWith(basename(files), "_")]
  if (!length(files)) return(list())

  posts <- lapply(files, function(f) {
    fm <- read_front_matter(f)
    if (is.null(fm$title) || is.null(fm$date)) return(NULL)
    list(
      title       = fm$title,
      date        = as.Date(as.character(fm$date)),
      description = fm$description,
      path        = f
    )
  })
  posts <- Filter(Negate(is.null), posts)
  if (!length(posts)) return(list())

  posts[order(vapply(posts, function(p) as.numeric(p$date), numeric(1)),
              decreasing = TRUE)]
}

posts_block <- function(dir = "blog/posts", n = 3) {
  posts <- list_posts(dir)
  if (!length(posts)) return(invisible(NULL))

  cat("::: {.news}\n\n")
  for (p in posts[seq_len(min(n, length(posts)))]) {
    cat("::: {.item}\n\n")
    cat("[", format(p$date, "%b %Y"), "]{.date}\n\n", sep = "")
    cat("[", p$title, "](", p$path, ")", sep = "")
    if (!is.null(p$description)) cat(" — [", p$description, "]{.subtle}", sep = "")
    cat("\n\n:::\n\n")
  }
  cat(":::\n\n")
}

# ── People ───────────────────────────────────────────────────────
people_block <- function(file = "people.yml", group = NULL) {
  people <- read_data(file)
  if (!is.null(group)) people <- Filter(function(p) identical(p$group, group), people)
  if (!length(people)) return(invisible(NULL))

  cat("::: {.people}\n\n")
  for (p in people) {
    cat("::: {.person}\n\n")

    if (!is.null(p$photo) && nzchar(p$photo) && file.exists(p$photo)) {
      # raw HTML keeps Quarto from wrapping the image in a <figure>
      cat('<img src="', p$photo, '" alt="" class="headshot">\n\n', sep = "")
    } else {
      cat("::: {.headshot}\n:::\n\n")
    }

    cat("[", p$name, "]{.name}\n\n", sep = "")
    cat("[", p$role, "]{.role}\n\n", sep = "")

    row <- link_row(p$links)
    if (nzchar(row)) cat("[", row, "]{.subtle}\n\n", sep = "")

    cat(":::\n\n")
  }
  cat(":::\n\n")
}

# Collaborators read better as a list than as a photo grid
collaborators_block <- function(file = "people.yml") {
  people <- Filter(function(p) identical(p$group, "collaborator"), read_data(file))
  if (!length(people)) return(invisible(NULL))
  cat("::: {.roster}\n\n")
  for (p in people) {
    cat("::: {.entry}\n\n")
    cat("[", p$name, "]{.role-name}\n\n", sep = "")
    bits <- c(p$org, p$role)
    bits <- bits[!vapply(bits, is.null, logical(1))]
    if (length(bits)) cat("[", paste(unlist(bits), collapse = " &middot; "), "]{.subtle}\n\n", sep = "")
    cat(":::\n\n")
  }
  cat(":::\n\n")
}

alumni_block <- function(file = "people.yml") {
  people <- Filter(function(p) identical(p$group, "alumni"), read_data(file))
  if (!length(people)) return(invisible(NULL))
  for (p in people) {
    cat("**", p$name, "**", sep = "")
    if (!is.null(p$role)) cat(" — ", p$role, sep = "")
    if (!is.null(p$now))  cat(". Now ", p$now, sep = "")
    cat("\n\n")
  }
}

# ── Publications ─────────────────────────────────────────────────
pubs_block <- function(file = "publications.yml", highlight = character()) {
  pubs <- read_data(file)
  if (!length(pubs)) return(invisible(NULL))

  years <- vapply(pubs, function(p) as.integer(p$year), integer(1))
  ord   <- order(years, decreasing = TRUE)
  pubs  <- pubs[ord]
  years <- years[ord]

  for (y in unique(years)) {
    cat("## ", y, "\n\n", sep = "")
    cat("::: {.pubs}\n\n")

    for (p in pubs[years == y]) {
      authors <- p$authors
      for (h in highlight) authors <- gsub(h, paste0("**", h, "**"), authors, fixed = TRUE)

      cat("::: {.pub}\n\n")
      cat("[", authors, "]{.authors}\n\n", sep = "")
      cat(p$title, "\n\n", sep = "")
      cat("[", p$venue, "]{.venue}", sep = "")

      row <- link_row(p$links)
      if (nzchar(row)) cat(" [", row, "]{.subtle}", sep = "")

      cat("\n\n:::\n\n")
    }
    cat(":::\n\n")
  }
}

# ── Year-stamped list (posters, talks, awards) ───────────────────
listing_block <- function(items) {
  if (is.null(items) || !length(items)) return(invisible(NULL))
  years <- vapply(items, function(x) as.integer(x$year), integer(1))
  items <- items[order(years, decreasing = TRUE)]
  years <- sort(years, decreasing = TRUE)

  cat("::: {.news}\n\n")
  for (i in seq_along(items)) {
    cat("::: {.item}\n\n")
    cat("[", years[i], "]{.date}\n\n", sep = "")
    cat(items[[i]]$text, "\n\n", sep = "")
    cat(":::\n\n")
  }
  cat(":::\n\n")
}

# ── Date-stamped list (press coverage) ───────────────────────────
media_block <- function(items, n = Inf) {
  if (is.null(items) || !length(items)) return(invisible(NULL))
  dates <- as.Date(vapply(items, function(x) as.character(x$date), character(1)))
  ord   <- order(dates, decreasing = TRUE)
  items <- items[ord]
  dates <- dates[ord]

  cat("::: {.news}\n\n")
  for (i in seq_len(min(n, length(items)))) {
    cat("::: {.item}\n\n")
    cat("[", format(dates[i], "%b %Y"), "]{.date}\n\n", sep = "")
    cat(items[[i]]$text, "\n\n", sep = "")
    cat(":::\n\n")
  }
  cat(":::\n\n")
}

# ── Timeline (positions, education) ──────────────────────────────
timeline_block <- function(entries) {
  if (is.null(entries) || !length(entries)) return(invisible(NULL))
  cat("::: {.timeline}\n\n")
  for (e in entries) {
    cat("::: {.entry}\n\n")
    cat("[", e$period, "]{.period}\n\n", sep = "")
    cat("::: {.detail}\n\n")
    cat("[", e$role, "]{.role-name}\n\n", sep = "")
    if (!is.null(e$org)) cat("[", e$org, "]{.org}\n\n", sep = "")
    emit(e$body)
    cat(":::\n\n")
    cat(":::\n\n")
  }
  cat(":::\n\n")
}

# ── Software / pipeline entries ──────────────────────────────────
tools_block <- function(tools) {
  if (is.null(tools) || !length(tools)) return(invisible(NULL))
  for (t in tools) {
    cat("::: {.tool}\n\n")
    cat("[", t$name, "]{.tool-name}", sep = "")
    if (!is.null(t$status)) cat(" [", t$status, "]{.tool-status}", sep = "")
    cat("\n\n")
    if (!is.null(t$tagline)) cat("[", t$tagline, "]{.tool-tagline}\n\n", sep = "")
    emit(t$body)
    row <- link_row(t$links)
    if (nzchar(row)) cat("[", row, "]{.subtle}\n\n", sep = "")
    cat(":::\n\n")
  }
}

# ── Software list ────────────────────────────────────────────────
software_block <- function(items) {
  if (is.null(items) || !length(items)) return(invisible(NULL))
  for (s in items) {
    label <- if (!is.null(s$url)) sprintf("[%s](%s)", s$name, s$url) else s$name
    cat("- **", label, "** — ", s$description, "\n", sep = "")
  }
  cat("\n")
}

# ── Contact block ────────────────────────────────────────────────
contact_block <- function(contact) {
  if (is.null(contact) || !length(contact)) return(invisible(NULL))
  if (!is.null(contact$lines)) {
    cat(paste(contact$lines, collapse = "  \n"), "\n\n", sep = "")
  }
  if (!is.null(contact$email)) cat("<", contact$email, ">\n\n", sep = "")
  emit(contact$note)
}
