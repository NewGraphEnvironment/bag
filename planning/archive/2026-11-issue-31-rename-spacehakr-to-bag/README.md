# spacehakr → bag: rename, narrow to fetching, take in ten functions (#31)

## Outcome

`spacehakr` became `bag` and stopped being a grab bag. The repository was renamed in place
(so GitHub's redirect and the `v0.4.2` tag keep every old `Remotes:` entry resolving), ten
exports and two internal helpers were re-prefixed `bag_`, the ten spatial and
drone-imagery helpers nothing in this namespace called were deleted with their imports, and
ten functions came the other way from two older first-party packages whose subject is
reporting rather than fetching. `magrittr` went with them: `Imports` is 15, down from 19,
and `Suggests` 5, down from 12. Released as `bag` 0.5.0.

The expensive lesson was about **measuring against the remote, not the disk**. The plan
asserted that `ngr` held independent copies of the twelve `ngr_spk_*` functions and did not
depend on this package, so deleting its copies "strands nobody". Every sentence of that was
false: `ngr` carries `spacehakr` in `Imports:` and `Remotes:`, and all twelve are one-line
forwarders. It surfaced only because pinning one consumer turned the *other* consumer's CI
red with `dependency conflict` — the exact failure "pin everywhere or nowhere" describes.
The near miss is the part worth keeping: the local `ngr` checkout was ten commits stale and
genuinely carried no `spacehakr` line, so grepping it instead of `origin/main` would have
*confirmed* the error. The repo's original `CLAUDE.md` had it right; the planning session's
"correction" of it was the mistake, and it survived four review rounds because every round
read the plan rather than the remote.

Four review rounds found 33 defects, every one reproduced before being fixed and 26
mutations checked red. Two were data loss: a GeoPackage backup that passed `delete_dsn` and
destroyed sibling layers, and a coordinate assignment that clobbered a caller's column.
Round 3 named the mechanism the rounds kept finding — *a fix lands on the caller the
symptom arrived through, and the sibling over the same container keeps the behaviour* — and
the loop ended on a mechanical enumeration of every guard, not on a reviewer saying it had
converged. Round 4 was about identity rather than code and found five false statements in
text this session had written: a Suggests count, an "Eleven", forwarders said to exist that
do not, a consumer said to be pinned when only a PR was open, and a `CITATION.cff` recipe
regression. One of this session's own gates also failed toward pass: `example()` was used to
prove the README's examples run, and it *skips* `\dontrun{}`, so it returned OK on examples
a regex had failed to unwrap.

## Measurement

- **Dependency reduction:** `Imports` 19 → 15, `Suggests` 12 → 5, `magrittr` removed
  entirely. Exports 14, each with an `Rd`, a test file and one of four `@family` tags
  (`download` 3, `catalogue` 4, `files` 4, `coordinates` 3).
- **Suite:** FAIL 0, WARN 0, SKIP 2, PASS 377; `lintr` 0; `check(vignettes = FALSE)`
  0 errors / 0 warnings / 0 notes.
- **Zenodo followed the rename with no relinking** — the question the owner asked, settled
  by measurement rather than by reading `invenio_github`'s source. The concept DOI
  `10.5281/zenodo.23524742` resolves to record `23864079`, titled `bag: Fetch Public Data
  and Field Files to Disk`, version `v0.5.0`, `isSupplementTo` the `v0.5.0` tree. The
  integration keys on the numeric GitHub repository id, which a rename does not change.
  Durable form in soul's `research/software-citation.md`.
- **Caller census, across local checkouts rather than from the plan:** six of `ngr`'s
  twelve forwarders have external callers and six have none; three repos are involved —
  `restoration_wedzin_kwa_2024` (nine calls across five functions), `stac_uav_bc`
  (three × `ngr_spk_odm`), `fish_passage_peace_2024_reporting` (one × `ngr_spk_join`).
  GitHub code search rate-limited mid-run, so it is a local-disk census and says so.
- **Settled the umbrella issue's open ODM conditional** from the other direction: drone
  jobs do still run, and `stac_uav_bc` is the only caller, which makes it a rehoming
  candidate rather than a restore.
- **Fifteen barred private-repo references were in this repo's own `planning/`**, found by
  enumerating the 72 private repos and grepping for the two barred forms rather than by
  recalling where they might be. Four had been public since September. All are words now;
  git history retains them, and nothing gates a public repo's tracked files, which is the
  finding rather than the fix.
- A deliberate non-change: the site, the release and the citation file were each checked
  against the artifact rather than the workflow status. `gh-pages` reads
  `Deploying to gh-pages from @ NewGraphEnvironment/bag@db0b8fc`, the merge SHA, and the
  served page returns 200, titles for `bag` and contains **zero** `spk_` references.

## Owed

Owed by other repositories, each now tracked where the work happens — nothing here is
waiting on this repo:

- [ ] Unpin **both** consumers once each switch PR has landed — pin everywhere or nowhere,
      so neither comes off alone. Owed after
      [ngr#47](https://github.com/NewGraphEnvironment/ngr/issues/47) and the other
      consumer's counterpart issue
- Switch the public caller: tracked as
  [restoration_wedzin_kwa_2024#165](https://github.com/NewGraphEnvironment/restoration_wedzin_kwa_2024/issues/165).
  The call is on an unmerged branch, every argument keeps its name in `bag_url()`, and
  that repo has no `DESCRIPTION`, so nothing there needs pinning.
- Switch the two consumers that declare the dependency, and grep each for the **bare**
  package name as well as the namespaced call: the public half is
  [ngr#47](https://github.com/NewGraphEnvironment/ngr/issues/47); the other consumer's
  counterpart issue now carries the per-file measurement of the four things that break on
  the name, including the one that fails in the quiet direction — its deprecation test is
  gated on `skip_if_not_installed()`, so after the rename it **skips** rather than fails.
- Deprecating forwarders in the two donor packages:
  [fpr#141](https://github.com/NewGraphEnvironment/fpr/issues/141) carries `fpr`'s four
  with the name mapping; the other donor's half is tracked by its own counterpart issue.
- The R&D tracking issue's title still names `spacehakr`, so `rnd_issue.sh` returns `NONE`
  for this repo and future PRs here will miss the R&D line. Retitling is the owner's call.

## Closed by

[PR #35](https://github.com/NewGraphEnvironment/bag/pull/35), merged as `db0b8fc`, released
as [v0.5.0](https://github.com/NewGraphEnvironment/bag/releases/tag/v0.5.0).
