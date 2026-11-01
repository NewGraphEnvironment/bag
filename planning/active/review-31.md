# Plan review — #31 (pre-baseline)

One Plan-agent review of the draft breakdown, run against the issue, the umbrella and
counterpart issues, and the working tree. Findings were reproduced before being acted on,
in both directions. Verdicts below are mine, from those probes.

## Blockers — both confirmed, both folded into the plan

| finding | verdict | what changed |
|---|---|---|
| The pkgdown and `DESCRIPTION` URLs cannot be correct before the repo is renamed, because the Pages path derives from the repo name | **CONFIRMED.** `gh api .../pages` → `html_url: http://www.newgraphenvironment.com/spacehakr/`, `cname: null`. Refinement: *both* candidate URLs return 200 and the `.github.io` form 302s to the `www` one, so it is a style choice, not a broken alias — but either path contains the repo name, so the ordering point stands | The repository rename became Phase 1, ahead of all identity edits. Also surfaced a **third** stale URL copy in `CLAUDE.md` that the draft missed |
| Merging `Package: bag` makes the one declaring consumer uninstallable, and the draft undercounted the damage | **CONFIRMED**, with one correction: the tripwire test is gated on `skip_if_not_installed()`, so post-rename it goes **quiet** rather than failing. The install failure is the real break | New Phase 8 item: pin that consumer to `@v0.4.2` *before* merge. Justified by a measured fact — the second consumer `CLAUDE.md` names has no `Remotes` entry at all, so a single-consumer pin satisfies "pin everywhere or nowhere" |

A third item, "Verification lists a post-merge check as a merge gate", was **confirmed** and
the Verification section now says so explicitly.

## Claims I asked it to check, and what the probes said

| claim | verdict |
|---|---|
| No keeper calls a deleted function | **CONFIRMED**, plus one reference the draft missed: `R/spk_source_url.R:357`, an `@noRd` block linking `[spk_gdalwarp()]` — invisible to `check`, visible to the grep gate |
| `terra` reachable only from the deleted set | **CONFIRMED.** Four files plus a `@seealso`; the `spk_odm.R` hit is the word "terrain" |
| The dropped `Suggests` are unreachable from the keepers, tests included | **CONFIRMED**, and the draft stopped one short of its own rule: `knitr` and `rmarkdown` also become unreachable |
| Both articles document only the deleted STAC function | **CONFIRMED** |
| `points.gpkg` / `poly.gpkg` — which can go? | **ANSWERED: keep `poly.gpkg`**, read by `test-spk_layer_info.R:5, 18, 99`. `points.gpkg` only by the deleted join test and `README.Rmd:74` |
| `globalVariables()` — what survives? | **CONFIRMED: `driver` and `name`.** Plus a miss in the draft: `@importFrom stats setNames` is dead, its only users being two deleted files |
| The pruned `Imports:` list | **DRAFT WAS WRONG.** It named 13 and hedged; three of those (`rlang`, `tibble`, `xml2`) are unreachable. Target is **10**. Verified per-package: `rlang` appears only as `@importFrom rlang .data` in the deleted join |

## Findings I did not adopt as stated

- **Donor test counts.** The review said nine of eleven untested, correcting the draft's
  nine — then gave numbers adding to seven. Listing both `tests/testthat/` directories
  gives **seven of eleven** (four of the internal package's seven, three of `fpr`'s four).
  The plan says seven. The review was right that the draft was wrong and wrong about the
  replacement, which is why the probe mattered.
- **"Phase 1's tag is near-redundant."** Stronger than that: `git diff v0.4.2..HEAD` over
  `R/`, `tests/`, `man/`, `NAMESPACE`, `DESCRIPTION`, `inst/` is **empty**, so `v0.4.2`
  *is* the pre-deletion tag. The phase was dropped rather than annotated.
- **"`v0.4.2` stays installable by tag through the redirect" is untested.** Fair; it is
  now an explicit item under Verification rather than an assumption.

## Gaps it found that the draft had no item for

`CITATION.cff` (eight hits, and its workflow only fires on a push to `main` touching
`DESCRIPTION`, so it stays stale on a feature branch); `dev/vm_packages.md`;
`planning/README.md:33`, which a gate exempting only `planning/archive/` still trips on;
`README.Rmd`'s two CI badge URLs and logo `alt` text; six further `CLAUDE.md` sites; an
internal ecosystem registry row; the ten `mockery::stub()` string targets; the `@family`
tags left as single-member families; and the fact that the README rewrite is **writing the
first examples** for the two functions the package exists for, which appear nowhere in it
today.

Two acceptance gaps worth naming on their own:

- **`pkgdown::check_pkgdown()` is vacuous here** — no `reference:` section, so nothing to
  check. The plan now adds one.
- **Three checks were missing**: that `NAMESPACE` export count, `man/*.Rd` count and the
  intended function count agree; that `R CMD build`'s tarball carries no leaked `.Rproj`;
  and an end-to-end `pak::pkg_install()` into a clean library, which is the only check that
  would catch the consumer breakage.

## Scope

The review supported descoping the intake, correctly reading the counterpart issue's
ordering — but the user chose the **full scope** at the gate, which makes the umbrella
issue's members table (which puts the intake inside this issue's row) accurate as written.
No amendment owed there. The review's related point stands: the internal package's
counterpart issue already covers its seven, so no new issue is filed for them; `fpr` needs
one for its four.
