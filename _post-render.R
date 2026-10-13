# Runs after every `quarto render`.
#
# Quarto's draft-mode "gone" keeps drafts out of listings, feeds and the
# sitemap, but still writes an empty HTML shell at the post's URL. Remove
# those shells so a draft's address returns a proper 404 instead of a blank
# page.

out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", "docs")
files   <- list.files(out_dir, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
for (f in files) {
  if (file.size(f) > 200) next
  txt <- paste(readLines(f, warn = FALSE), collapse = "")
  if (grepl("^<!DOCTYPE html><html[^>]*></html>$", txt)) {
    unlink(f)
    cat("post-render: removed draft stub", f, "\n")
  }
}
# drop now-empty folders such as docs/blog/posts/
dirs <- list.dirs(out_dir, recursive = TRUE)
for (d in rev(dirs)) if (d != out_dir && !length(list.files(d, all.files = TRUE, no.. = TRUE))) unlink(d, recursive = TRUE)
