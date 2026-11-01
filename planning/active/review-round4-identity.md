# Review round 4 — the identity pass (commit `a8f74eb`)

Reviewer: round-4 identity reviewer, 2026-11-01. Scope: the single commit "Point the
package at its new name, and release bag 0.5.0".

Nothing in `/Users/airvine/Projects/repo/spacehakr` was edited. Two things were run
outside it: `R CMD build` + `R CMD check` from
`…/scratchpad/chk/`, and a full `cp -R` of the tree to
`…/scratchpad/cffcopy/` where `README.Rmd` was re-knitted and the `/citation-cff`
recipe was run to produce a reference `CITATION.skill.cff`. Both are in the scratchpad.

## Checklist read

INDEX files, in full:

- `…/scratchpad/review/checklist/code-check.INDEX.md`
- `…/scratchpad/review/checklist/code-check-r.INDEX.md` (115 rules)
- `…/scratchpad/review/checklist/code-check-shell.INDEX.md` (70 rules)
- `…/scratchpad/review/checklist/code-check-spatial.INDEX.md` (94 rules)

Full sections read where they bear on the diff: code-check.md "One fact derived twice",
"Written data outlives the fix", "Documentation Staleness", "A link to a repo-hosted
artifact must be *tracked*, not merely present", "A guard's scope, escape hatches, and
remedies"; code-check-r.md "`cffr::cff_create()` writes a CRAN DOI for any package that
shares a name with a CRAN package", "`R CMD build` ships every top-level directory not in
`.Rbuildignore`", "`.Rbuildignore` has no comment syntax", "Regenerated binaries churn git
even when nothing changed", "A `pkg::` call in a test passes `devtools::test()` and fails
`R CMD check`"; code-check-shell.md "`grep -c` prints the count AND exits 1 when it is
zero", "A verification command can be shadowed by a shell function or alias".

Conventions, in full:

- soul's `conventions/readme.md`
- soul's `conventions/writing.md`
- soul's `conventions/pkgdown-publishing.md`
- soul's `conventions/feature-workflow.md`, "Public-repo text describes the
  package, and points nowhere private" and "The version lives in one place"

Also read, because the diff's claims point at them:
soul's `skills/citation-cff/SKILL.md` and
`NewGraphEnvironment/flows/.github/workflows/r-citation-cff.yaml@v1`.

## Findings

Fourteen. Five of them (F1–F5) are statements a reader acts on that are false as the
commit stands.

---

### F1 — `NEWS.md`: "`Suggests` is 3, from 12". It is 5.

**Rule:** readme.md, "Check each claim against the code path a run takes" (and
code-check.md, "One fact derived twice").

`DESCRIPTION` Suggests is `DBI, mockery, RSQLite, testthat (>= 3.0.0), withr` — **five**.
The "from 12" half is right (`git show main:DESCRIPTION` has twelve). The arithmetic the
same bullet gives also lands on five, not three: the ten it names as removed leave
`mockery` and `testthat`, and `DBI`, `RSQLite` and `withr` arrived with the intake —
2 + 3 = 5.

The neighbouring Imports claim in the same bullet checks out: 14 on `main`
(`bcdata chk cli dplyr fs glue httr2 purrr rlang sf stringr terra tibble xml2`) and 15
now, `terra`/`xml2` out, `janitor`/`lubridate`/`readr` in.

**Fix:** `Suggests` is 5, from 12, and name the three that arrived if the sentence wants
to balance.

---

### F2 — "Functions added: **Eleven**" followed by a list of ten, in both `NEWS.md` and `CLAUDE.md`

**Rule:** code-check.md, "One fact derived twice".

`NAMESPACE` has 14 exports. Four are the renamed keepers (`bag_url`, `bag_bcdc`,
`bag_wfs`, `bag_layers`), so **ten** were added — which is exactly what the NEWS bullets
then enumerate: 3 catalogue + 4 files + 3 coordinates. Eleven donor functions were
*planned* (`planning/active/findings.md`, "Eleven, not nine as first assumed"), and the
same NEWS entry says three paragraphs later that one of them, the layer remover, "was then
dropped from this package altogether". So eleven came to the gate and ten landed.

`CLAUDE.md` carries the same number: "Eleven more functions came the other way in the same
release".

**Fix:** ten in both places, or say "eleven were taken in and one was dropped" in the
sentence that gives the number.

---

### F3 — "Those packages keep deprecating forwarders, so their callers are not broken" is not true yet

**Rule:** readme.md, "Describe nothing that is not fully built" (and writing.md, "Cut what
serves the authors" — "No pointer to pending work, and no word that dates").

In `NEWS.md` ("## Functions added") and again in `CLAUDE.md` ("## History"). Measured on
the donors' current default branches:

- `fpr`: no `deprecate_warn`, no `lifecycle::deprecated`, no `bag::` anywhere in `R/`.
  `fpr#141`, "Deprecating forwarders for the four helpers now in `bag`", was **filed
  today at 15:22Z** — after this commit — so it is open work, not shipped.
- `rfp` (`origin/main`, `a901caa`): forwarders exist for `rfp_source_url`,
  `rfp_source_bcdata` and `rfp_source_csv` only — an earlier move. None of the six
  functions this release took has one: `rfp_bcd_get_data.R`, `rfp_meta_bcd_xref.R`,
  `rfp_meta_bcd_xref_col_comments.R`, `rfp_gpx_import.R`, `rfp_fs_backup.R` and
  `rfp_gpkg_to_geojson.R` all still hold their full bodies.

`planning/active/task_plan.md` Phase 8 agrees: "Land the deprecating forwarders in both
donor repos" is **unticked**.

The conclusion the sentence draws happens to hold, for a different reason: the donors keep
their own working implementations, so nothing is broken. That is what the release note
should say, because a reader told "deprecating forwarders" will expect a deprecation
warning and get none.

**Fix:** "Those packages keep their own copies, so their callers are not broken;
deprecating forwarders are tracked in each." Then it stays true whichever way Phase 8
lands.

---

### F4 — `CLAUDE.md`: the consumer "is **pinned** to `@v0.4.2`". It is not.

**Rule:** readme.md, "Describe nothing that is not fully built" (stated as fact, work not
landed).

Measured after `git fetch`, on `rfp` `origin/main` (`a901caa`, 2026-10-27):

```
Remotes:
    NewGraphEnvironment/spacehakr,
    NewGraphEnvironment/ngr,
    NewGraphEnvironment/gq
```

Unpinned. The pin exists only on `origin/spacehakr-pin-pre-rename`, behind the **open** PR
`rfp` #419 ("Pin `spacehakr` to v0.4.2 ahead of its rename"), and Phase 8's first item —
"**Before this branch merges:** pin the one consumer" — is unticked.

This matters more than a tense: the rewritten "Why" paragraph rests on the pin being in
place ("With a single consumer holding an entry, 'pin everywhere or nowhere' is satisfied
by pinning that one, so the conflict cannot arise"). As written, `CLAUDE.md` tells the next
session the hazard is already handled while the hazard is live — `findings.md` spells it
out: merging `Package: bag` makes that consumer uninstallable, and nine reporting repos
install it.

**Fix:** state it as the condition it is — the entry is to be pinned to `@v0.4.2` before
this branch merges (rfp PR open) — and reword the "Why" paragraph so it does not assume
the pin. Describing the consumer without naming it is right and should stay
(feature-workflow.md, "No links to private repos").

---

### F5 — `CITATION.cff` was regenerated with a bare `cffr::cff_write()`, not the `/citation-cff` recipe, and CI will overwrite it

**Rule:** code-check-r.md, "`cffr::cff_create()` writes a CRAN DOI for any package that
shares a name with a CRAN package" (the same generator's trap set), plus code-check.md,
"One fact derived twice".

Reproduced: a `cp -R` of the tree, then the exact recipe from
`soul/skills/citation-cff/SKILL.md`, written to `CITATION.skill.cff`. The committed file is
388 lines; the recipe's is 49. The differences are all the parts the recipe exists to
force:

| committed | recipe |
|---|---|
| `message: 'To cite package "bag" in publications use:'` | `message: If you use bag, please cite it by its DOI, 10.5281/zenodo.23524742.` |
| `references:` — 339 lines, one entry per **locally installed** dependency | stripped (`x$references <- NULL`) |
| `preferred-citation: type: manual` with `institution:`, `year:`, `notes:` | `type: software` with `publisher: name: New Graph Environment Ltd.` |
| preferred-citation has no `doi`, `license`, `date-released` or `repository-code` | all four present, `doi: 10.5281/zenodo.23524742` |
| preferred-citation `url:` is the GitHub repo | the pkgdown site |

The old file (diff lines 85, 109–127) *did* follow the recipe, so this is a regression, not
a first run.

Two consequences, both concrete:

1. `references:` is environment-dependent — the skill says so in as many words, and the
   list in the committed file is this machine's library. `.github/workflows/update-citation-cff.yaml`
   fires on a push to `main` touching `DESCRIPTION` and calls
   `NewGraphEnvironment/flows/.github/workflows/r-citation-cff.yaml@v1`, which runs the
   canonical recipe. So on merge a bot commit will replace this file with the 49-line
   version — the committed content is both wrong and transient.
2. Until then, `preferred-citation` carries no DOI and no publisher, which is what
   GitHub's "Cite this repository" and Zenodo read.

Verified separately and fine: no CRAN package named `bag` (404), so no CRAN DOI was
injected; `citation("bag")` prints the Zenodo DOI, so the commit message's claim about
`inst/CITATION` holds; `doi: 10.5281/zenodo.23524742` resolves (200).

**Fix:** regenerate with the skill's recipe (or run the workflow by hand) and commit that.

---

### F6 — `README`: "Every exported function is documented with a runnable example". None of the 14 runs; at least 5 cannot.

**Rule:** readme.md, "Check each claim against the code path a run takes".

All 14 `man/*.Rd` have an `\examples` block and **all 14 are wrapped in `\dontrun{}`** — so
on the page the sentence points at, every example renders as `if (FALSE) { # \dontrun{` with
no output, and `R CMD check` ran none of them. Five could not run if a reader pasted them:

- `bag_layers("path/to/data.gpkg")` — a placeholder path.
- `bag_sf_from_utm(pscis_all)` — `pscis_all` is undefined anywhere in the package.
- `bag_backup(path_dir_in = "~/Projects/gis/my_project", …)`,
  `bag_gpkg_to_geojson(dir_in = "~/gps", …)`,
  `bag_gpkg_refresh(path_gpkg = "~/Projects/gis/my_project/form_fiss_site_2026.gpkg", …)` —
  paths on nobody's machine.

The bundled fixture that would make several of them real is right there and unused:
`inst/extdata/poly.gpkg` is referenced by `tests/` and by this README, and by **no** `.Rd`.
`r-packages.md` asks for the opposite — "no `\dontrun{}` unless external resources are
required" and "use bundled test data via `system.file()`".

**Fix:** either drop the word (the reference index is still worth pointing at), or say
what is true — "every exported function is documented, with examples for the ones that
need no network". The durable fix is to unwrap the three coordinate functions and
`bag_layers()` onto `system.file("extdata", "poly.gpkg", package = "bag")`, but that is
code, not this commit.

---

### F7 — `README`: "`fwapg` and the BC Data Catalogue are where most of the data it fetches comes from"

**Rule:** writing.md, "State each claim by the code's definition".

`fwapg` occurs in exactly two places in the whole repo: that sentence in `README.Rmd:115`
and its knit in `README.md:129`. There is no fwapg source, no fwapg URL, nothing in `R/`
that knows the name. What `bag` fetches is whatever the caller names — an arbitrary URL
through a GDAL virtual filesystem, a BCDC record, a WFS layer, or GPX files off a unit. The
BCDC half is true and load-bearing (`bcdata` is an Import); the fwapg half describes our
reporting stack's inputs, not this package's.

Secondary, same sentence: readme.md item 8 says a named source "links to its own site
where it has one … not to its GitHub repo" — fwapg has `https://smnorris.github.io/fwapg/`.

**Fix:** drop fwapg from the claim, or move it into a sentence about the reporting stack
that does not say bag fetches from it.

---

### F8 — `README` tells the reader to install a tag that does not exist

**Rule:** feature-workflow.md, "The version lives in one place"; readme.md, "State
development status with a lifecycle badge, not a warning in the prose".

```r
# or pin a release
pak::pkg_install("NewGraphEnvironment/bag@v0.5.0")
```

`git ls-remote --tags origin` returns six tags, `v0.1.0` … `v0.4.2`. There is no `v0.5.0`,
and this commit deliberately does not cut one ("The tag and the GitHub release are
deliberately not cut here"). As committed, the README's pin line fails for every reader,
and it will keep failing for as long as the PR is open.

Both conventions also say the line should not carry a literal version at all: readme.md
wants `pak::pak("<owner>/<pkg>@vX.Y.Z")` as a placeholder "so no version string enters the
prose", and feature-workflow.md keeps the current version in `DESCRIPTION`/`NEWS.md` only.
That form fixes the broken command and the drift in one edit.

**Fix:** `pak::pkg_install("NewGraphEnvironment/bag@vX.Y.Z")` with the NEWS link beside it,
which the paragraph above already has.

---

### F9 — `CLAUDE.md`'s rename table header says all four names were "in ngr". Two never were.

**Rule:** writing.md, "State each claim by the code's definition".

```
| in ngr, and here up to the rename | here now |
| `spk_source_url()`    | `bag_url()`    |
| `spk_source_bcdata()` | `bag_bcdc()`   |
| `spk_geoserv_dlv()`   | `bag_wfs()`    |
| `spk_layer_info()`    | `bag_layers()` |
```

`ngr`'s NAMESPACE exports exactly twelve `ngr_spk_*` functions; there is no
`ngr_spk_source_url` and no `ngr_spk_source_bcdata` (both were added in spacehakr after the
extraction — `git show main:CLAUDE.md`'s migration table lists the same twelve and neither
of these). The header also contradicts the paragraph directly above it, which says "Of
those twelve functions, **two** are still here under new names" — and that sentence is
correct.

`NEWS.md`'s equivalent table is headed "spacehakr 0.4.2 | bag 0.5.0" and is right; only
`CLAUDE.md`'s header over-claims.

**Fix:** head the column "up to the rename" and drop "in ngr", or split the two ngr rows
out.

---

### F10 — `CLAUDE.md`: "The four functions donated from older packages arrived with magrittr pipelines"

**Rule:** writing.md, "State each claim by the code's definition".

Counted `%>%` in the donor sources on their current trees — **eight** of the eleven donor
files carry magrittr pipelines:

| donor file | `%>%` |
|---|---|
| `fpr/R/fpr_sp_assign_utm.R` | 17 |
| `fpr/R/fpr_sp_gpkg_backup.R` | 7 |
| `fpr/R/fpr_sp_assign_sf_from_utm.R` | 5 |
| `fpr/R/fpr_sp_assign_latlong.R` | 3 |
| `rfp/R/rfp_meta_bcd_xref.R` | 17 |
| `rfp/R/rfp_meta_bcd_xref_col_comments.R` | 4 |
| `rfp/R/rfp_meta_bcd_xref_pkg_schtab.R` | 4 |
| `rfp/R/rfp_bcd_get_data.R` | 2 |

The three with none: `rfp_fs_backup.R`, `rfp_gpkg_to_geojson.R`, `rfp_gpx_import.R`.

"Four" is the batch magrittr was briefly taken as a dependency *for*
(`progress.md`: "confined to the four ported functions"), not the donation. Written as "The
four functions donated from older packages" two paragraphs under "Eleven more functions
came the other way", the file contradicts itself about how many were donated.

`NEWS.md`'s version — "The donated functions arrived with magrittr pipelines and were
rewritten to the native pipe" — is accurate and needs no change.

**Fix:** drop "four" in `CLAUDE.md`, matching NEWS.

The companion claim in the same paragraph, "no newer package of ours declares it or uses
`%>%` in `R/`", holds: `gq`, `drift`, `flooded`, `link`, `wet`, `fresh`, `fly` and
`knowledge` are all 0 on both counts. (`ngr` has one `%>%` in one `R/` file and does not
declare magrittr, but `ngr` is the older package this family came from, so it is not a
counterexample to "newer".)

---

### F11 — `CLAUDE.md`: "`inst/extdata/` — Test fixtures, used by tests and examples"

**Rule:** code-check.md, "Documentation Staleness".

No `man/*.Rd` contains `system.file` — grep over all 14 returns nothing. `inst/extdata/poly.gpkg`
is read by `tests/testthat/test-bag_layers.R` and `tests/testthat/test-bag_gpkg_to_geojson.R`,
and by `README.Rmd`. It is used by tests and by the README, not by examples (F6 is why).

**Fix:** "used by tests and the README", until the examples use it.

---

### F12 — `CLAUDE.md`: "Internal helpers are dotted"

**Rule:** code-check.md, "A guard's scope, escape hatches, and remedies" (the quantifier
half — walk the per-member evidence before writing the quantifier).

Nine of ten are: `.bag_bcdc_schtab`, `.bag_chk_sf_point`, `.bag_crs_unusable`,
`.bag_gpkg_layers`, `.bag_ogr2ogr`, `.bag_reencode`, `.bag_source_resolve`,
`.bag_url_args`, `.bag_warn_unplaced`. The tenth is `stderr_tail()`
(`R/bag_url.R:294`, `@noRd`, not exported, called at `:276`).

Low stakes, but `CLAUDE.md` is instructions: a contributor reading "internal helpers are
dotted" and then `stderr_tail()` has to work out which is wrong.

**Fix:** rename it `.bag_stderr_tail()` (one definition, one call site), or soften the
sentence.

---

### F13 — the repo's GitHub **About** text is empty while the tagline, `Title` and `Description` were all rewritten

**Rule:** readme.md, "Write the tagline, the description field, the GitHub About and the
opening together".

`gh repo view NewGraphEnvironment/bag --json description` returns `""`. The rule exists
because "each is read somewhere the others are not" — About is the repo card, and it is the
first thing a stranger arriving from a search sees. The three in-repo texts agree with each
other (README tagline, `Title: Fetch Public Data and Field Files to Disk`, and the
`Description` field), so there is nothing to reconcile, only to set.

**Fix:**

```bash
gh repo edit NewGraphEnvironment/bag --description "Fetch public spatial data and field files to disk."
```

---

### F14 — `README` Installation does not say a run needs GDAL's `ogr2ogr` on the PATH

**Rule:** readme.md, "Sections run in a fixed order" (item 4: Installation "followed by
what a run needs"), and its "A requirements sentence is a claim about each path it names".

`bag_url()` — the first capability the opening names, and the second block in the unrun
chunk — stops dead without the GDAL command-line tool:

```r
# R/bag_url.R:207
if (!nzchar(Sys.which("ogr2ogr"))) {
  cli::cli_abort("`ogr2ogr` is not on the PATH. Please install GDAL.")
}
```

`pak::pkg_install()` does not supply it, and `sf` bundling GDAL does not put `ogr2ogr` on
the PATH. The README's install section is two commands and nothing else, so a reader on a
fresh machine meets the abort instead of the requirement.

**Fix:** one sentence under the install block — `bag_url()` shells out to GDAL's `ogr2ogr`,
so GDAL has to be installed and on the PATH.

---

## Checked and clean

Everything below was verified against the artifact, not the commit message.

**The examples.** Both evaluated chunks reproduce **byte for byte** against the installed
0.5.0: `bag_layers(gpkg)[, c("name","geomtype","features","fields")]` gives the one `poly`
row shown, and `bag_layers()` does return a fifth `crs` column, so "trimmed here" is
honest. `bag_assign_utm(sites)` gives the four rows, both warnings and the
`POINT EMPTY`/`NA` row exactly as printed, and "Rows come back ordered by zone" is the
function's documented and implemented behaviour (`R/bag_assign_utm.R`: `zones <-
unique(sort(epsg[placed]))`, one pass per zone, unplaced appended last). Re-knitting
`README.Rmd` in a copy reproduces `README.md` (only pandoc's rewrap and the YAML header
differ), so the knit is current.

**The unevaluated chunk's argument names are all real:** `bag_bcdc(bcdata_record_id,
path_gpkg, mask)`, `bag_url(urls, path_gpkg)`, `bag_gpx_import(dir_out,
layer_output_name, gpkg_name)`. And `"pscis-assessments"` is a live public BCDC record
(`package_show` → 200, "PSCIS Assessments").

**Every link resolves** (followed, with codes): `http://www.newgraphenvironment.com/bag/`
200, `…/bag/reference/` 200, the NEWS blob on `main` 200, the R-CMD-check badge/workflow
200, `https://github.com/smnorris/fwapg` 200, `https://doi.org/10.5281/zenodo.23524742`
200, `…/bag/issues` 200, `https://github.com/NewGraphEnvironment/ngr` 200. And
`http://www.newgraphenvironment.com/spacehakr/` is **404**, exactly as `NEWS.md` says. The
`/bag/` path already serves, carrying the pre-rename content until pkgdown next deploys —
consistent with the commit message, worth knowing when reading F6's link.

**`R CMD check` is genuinely 0/0/0.** Built and checked the 0.5.0 tarball in the
scratchpad: `Status: OK`, no WARNING/NOTE lines. (Checked specifically whether
`importFrom(tools, …)`/`importFrom(utils, …)` without those in `Imports:` would warn — it
does not, and the condition predates the branch.)

**Counts and agreements.** `Imports` 15 from 14, with the named three in and two out ✓.
Four `@family` tags at 3/4/4/3 (`download`, `catalogue`, `files`, `coordinates`) exactly as
`CLAUDE.md` states, and `_pkgdown.yml`'s four `has_concept()` groups cover all 14 exports ✓.
`.lintr` is genuinely new (`git show main:.lintr` → does not exist) ✓. `main`'s
`_pkgdown.yml` genuinely had no `reference:` section ✓. Both deleted articles mention only
`spk_stac_calc` ✓. `DESCRIPTION` `URL`/`BugReports`, `_pkgdown.yml` `url` and
`CITATION.cff` `repository-code`/`url` all name the new repository and agree ✓.
`ngr` exports all twelve `ngr_spk_*`, so NEWS's "all ten" and CLAUDE.md's "all twelve" are
both right ✓. Nothing in the org's checkouts calls the ten deleted names (one stray
`spk_res(path)` line in `ngr/rando/rando_stars_centrois.R`, a scratch file with no
`library()` call) ✓.

**The nine donor defects were filed**, each verified present in the donor first:
four with the internal package and [fpr#139](https://github.com/NewGraphEnvironment/fpr/issues/139),
[fpr#140](https://github.com/NewGraphEnvironment/fpr/issues/140). The three the NEWS entry
describes map onto fpr#139 (`!x != y`), the internal package's timezone drift and its
layer remover's data-loss path ✓.

**`spacehakr@v0.4.2` stays installable:** `gh api repos/NewGraphEnvironment/spacehakr`
answers `NewGraphEnvironment/bag`, and `v0.4.2` is on the remote ✓.

**Nothing internal leaked.** Grepped `README.Rmd`, `README.md`, `NEWS.md`,
`CITATION.cff`, `DESCRIPTION`, `_pkgdown.yml` and `CLAUDE.md` above the marker for private
repo names, host names, tunnels, `~/.Renviron` and `/Users/` paths: no hits. The consumer
is described without being named, which is what feature-workflow.md asks for. The
`Tailscale`/`ssh` hits in `CLAUDE.md` are all below the `<!-- BEGIN SOUL CONVENTIONS -->`
marker, in generated public-safe text. `.github/workflows/pkgdown.yaml` calls the shared
flow with `allowed-pages: 404 authors index LICENSE-text`, so the rewritten `CLAUDE.md` is
stripped before `build_site()` and a new root page would fail the build —
pkgdown-publishing.md satisfied, and the commit adds no root markdown.

**`.Rbuildignore` / `.gitignore`.** `^README\.html$` is a valid live regex (that file has
no comment syntax), it is the artifact `github_document` leaves behind, and it is not
tracked ✓.

## Noted, not a finding

- **`CLAUDE.md`, "white package-name text, Helvetica font".** `data-raw/make_hexsticker.R`
  does pass `p_family = "Helvetica"`, and `task_plan.md` records that the renderer warns
  and substitutes `sans` — so the sentence describes the request, not the rendered sticker.
  Recorded as a deliberate "noted, not changed" in the plan, so flagging it again would be
  re-litigating a decision; leaving it here so it is not lost.
- **`_pkgdown.yml`'s Files group `desc:`** — "Inspect, convert and back up spatial files" —
  does not cover `bag_gpkg_refresh()`, whose job is refreshing coordinate columns and
  writing back. readme.md asks each group `desc:` to cover every function under it. The
  `reference:` section is not part of this commit (only `url:` changed), so it is out of
  scope; mentioning it because the same rule governs the README sentence that points at it.
