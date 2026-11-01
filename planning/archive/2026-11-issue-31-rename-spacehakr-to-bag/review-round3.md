# Review round 3 — `bag` rename branch (`31-rename-spacehakr-to-bag-fetch-public-dat`)

Reviewer worked from a **copy** of the tree at
`/private/tmp/claude-501/-Users-airvine-Projects-repo-spacehakr/96953e68-6a89-4a65-a434-6e36d29b5c0a/scratchpad/work/bagcopy`
(`cp -r`), and loaded the package from that copy with `pkgload::load_all()`. The live tree at
`/Users/airvine/Projects/repo/spacehakr` was read only; nothing in it was edited except this
findings file, which the brief named as FINDINGS_PATH. No subagents were spawned.

Measured on R 4.5.2, sf 1.1.2, GEOS 3.13.0, GDAL 3.8.5, PROJ 9.5.1.

## Checklist read

- **code-check.INDEX.md** — in full. **code-check-r.INDEX.md** — in full.
  **code-check-shell.INDEX.md** — in full. **code-check-spatial.INDEX.md** — in full.
  (All four are reproduced verbatim as this repo's project instructions; `code-check.INDEX.md`
  was spot-diffed against the file on disk to confirm they are the same text.)
- **code-check.FULL.md** — `## Mechanisms`: the prose of **all 14** H3 sections read in full
  (tables skipped, as instructed). `## Rules that stand alone`, `## Security` and
  `## Spreadsheets and PDFs` — not read beyond their index lines (≈30 headings).
- **code-check-r.FULL.md** — index only; no section read in full this round. The R-language
  traps this diff touches (`glue()`, `tryCatch`, `cli` plurals, `bind_rows` of NULL,
  `expect_message`, `nzchar(NA)`, `[[` on an atomic, testthat `NOT_CRAN`) were walked as index
  lines against the diff; none of them was the subject of a finding, so none was opened.
  ≈110 headings not read in full.
- **code-check-shell.FULL.md** — read in full: "`system2(stdout = TRUE)` warns on a non-zero
  exit…" and "A variable in a sed replacement is parsed…" (the latter as the quoting analogue
  for `.bag_ogr2ogr()`'s `shQuote()`). ≈70 headings not read in full.
- **code-check-spatial.FULL.md** — read in full: "A GeoPackage is a SQLite database, and that
  leaks in three ways"; "The same leak reaches R and OGR SQL…"; "Ask the file about its field
  names, not R"; "sf: `st_read()` promotes a mixed POLYGON/MULTIPOLYGON layer…";
  "`sf::st_read()` on a KML drops `<SchemaData>`, silently"; "GeoJSON in a projected CRS is
  silently non-portable"; "`terra::project()` given only a CRS…". ≈100 headings not read in
  full.

---

# Part 1 — THE MECHANISM

## Name

**The fix lands on the caller the symptom arrived through, and the sibling over the same
container keeps the behaviour — and the pairing is this package's design, not an accident.**

This is `code-check.md`'s "A fix lands in one of two callers that share a harness", and its
own words name both the generator and the instrument:

> The count is the signal, not the instance: if you have fixed the same class twice in one of
> a pair, the pair is the bug.
>
> […] where the fix **added** a behaviour rather than corrected one, diff the two callers'
> contracts — options, guards, completeness statements, what each does on a degenerate input —
> instead of searching the sibling for the token you just wrote.

## Why it produces round 1's nine and round 2's two

`bag` is not fourteen independent functions. It is **six small sets of functions over one
shared container each** — and every member of a set was ported from a different donor, at a
different time, by a different hand:

| container | consumers in `R/` |
|---|---|
| K1 a multi-layer data source (`sf::st_layers()`) | `bag_gpkg_refresh`, `bag_gpkg_to_geojson`, `bag_layers` |
| K2 an `sf` layer's POINT features | `bag_assign_utm`, `bag_assign_latlong`, `bag_gpkg_refresh` (via `.bag_chk_sf_point`) |
| K3 the UTM zone/easting/northing column triple | `bag_assign_utm` (writes), `bag_sf_from_utm` (reads), `bag_gpkg_refresh` (persists) |
| K4 a layer's CRS as a transform source | `bag_gpkg_to_geojson` (via `.bag_crs_unusable`), `bag_gpkg_refresh`, `bag_assign_utm`, `bag_assign_latlong`, `bag_layers` |
| K5 a `bcdata` search result's packages | `bag_bcdc_index`, `.bag_bcdc_schtab` |
| K6/K7 a URL vector; a file on disk | `bag_url`; `bag_backup`, `bag_gpx_import` |

A donor defect surfaces through **one** member. But the property each round-1/round-2 fix
encodes is a property of the **container**, so it is owed to every member of that container's
set:

- *"a support table is not the layer I mean"* (round 2 fix #3) → owed to all of K1.
- *"a row the arithmetic cannot place is carried, not dropped, and the caller is told"*
  (round 2 fix #1) → owed to all of K2, and its output shape is owed to all of K3.
- *"an `srs_id` 0 CRS transforms without complaint and silently takes the coordinates for
  WGS 84"* (round 2 fix #2) → owed to all of K4.
- *"the CRS object, not `st_crs(parameters = TRUE)$epsg`"* (round 1 fix #6) → owed to all of K4,
  and **was** applied to both members, which is what a correctly-propagated fix looks like.

Round 2's two in-fix findings are the same mechanism one level in. Each replaced a
container-level **proxy** with another container-level proxy — `is.na(st_crs())` for "unusable
CRS", `length(st_layers()$name)` for "ambiguous or destructive" — rather than putting the
property somewhere both members reach. Round 2 then did the right thing once: it extracted the
property into a helper, `.bag_crs_unusable()`. **And wired that helper into one of K4's two
GeoPackage consumers.** That is the mechanism reproducing itself inside its own remedy, which
is why a quiet round cannot close it.

## Why the fixtures cannot see it

`code-check.md`, "A fixture that cannot reach the failure mode": each test file builds its
fixture from *the function under test's own happy path*, so the axis that separates the pair is
the one axis no fixture varies. The evidence is a grep, not an impression — the `layer_styles`
fixture exists in **exactly one** test file in the repo:

```
tests/testthat/test-bag_gpkg_refresh.R:341:  "CREATE TABLE layer_styles (...)"
```

— the file for the member that was fixed. Nothing in `test-bag_gpkg_to_geojson.R` or
`test-bag_layers.R` builds one, although both read the same files in production. Likewise
`test-bag_sf_from_utm.R:85` has a `bag_assign_utm → bag_sf_from_utm` round-trip test, and its
fixture is three well-formed points — the one input shape round 2's fix #1 was written for is
absent from it.

---

# Part 2 — THE ENUMERATION

Instrument, taken from the rule itself: **for every container with more than one consumer, run
every consumer over every degenerate input that container admits, and diff the contracts.**

Degenerate axes, derived from the container kinds rather than recalled:

| axis | meaning |
|---|---|
| D1 | a member of a different kind (an aspatial support table beside a spatial layer) |
| D2 | a member with no value (empty geometry, NA coordinate, NA / out-of-range / mistyped zone) |
| D3 | an empty container (zero features, zero rows, zero layers, zero files, zero URLs) |
| D4 | a member whose CRS is a GeoPackage reserved placeholder (`srs_id` 0 and −1) |
| D5 | a container with no names |

**Set walked: 26 cells.** Every cell was executed, not reasoned about; the driver is
`.../scratchpad/work/matrix2.R`, and the per-call-site parse that produced the consumer lists is
`.../scratchpad/work/enum.R` (46 container-accessor call sites across the 18 files in `R/`,
extracted with `utils::getParseData()` rather than grep, per "Enumerate by parsing").

```
 #  K    consumer                 axis                      verdict
 1  K1   bag_gpkg_refresh         D1 aspatial sibling        ok  [warn]
 2  K1   bag_gpkg_to_geojson      D1 aspatial sibling        ABORT  <- FINDING 1
 3  K1   bag_layers               D1 aspatial sibling        ok
 4  K1   bag_gpkg_refresh         D3 zero-feature layer      ok  [warn]
 5  K1   bag_gpkg_to_geojson      D3 zero-feature layer      ok
 6  K1   bag_layers               D3 zero-feature layer      ok
 7  K2   bag_assign_utm           D2 empty geometry          ok  [warn]
 8  K2   bag_assign_latlong       D2 empty geometry          ok  (silent, NaN)  <- FINDING 3
 9  K2   bag_gpkg_refresh         D2 empty geometry          ok  [warn]
10  K2   bag_assign_utm           D3 zero-feature            ok  [warn]
11  K2   bag_assign_latlong       D3 zero-feature            ok
12  K3   bag_sf_from_utm          D2 NA zone from sibling    ABORT  <- FINDING 2
13  K3   bag_sf_from_utm          D2 out-of-range zone       ABORT  <- FINDING 2
14  K3   bag_sf_from_utm          D2 character zone          ABORT  <- FINDING 2
15  K3   bag_sf_from_utm          D3 zero-row                ok
16  K3   bag_assign_utm           D3 zero-feature            ok  [warn]
17  K4   bag_gpkg_to_geojson      D4 srs_id 0                ABORT (by design)
18  K4   bag_gpkg_refresh         D4 srs_id 0                ok  (proceeds)  <- FINDING 4
19  K4   bag_layers               D4 srs_id 0                ok
20  K4   bag_gpkg_to_geojson      D4 srs_id -1               ABORT (by design)
21  K4   bag_gpkg_refresh         D4 srs_id -1               ABORT (GDAL, unnamed)  <- FINDING 4
22  K4   bag_layers               D4 srs_id -1               ok
23  K5   bag_bcdc_index           D5 unnamed search result   ABORT (loud; see below)
24  K6   bag_url                  D3 zero urls               ok
25  K7   bag_gpx_import           D3 absent directories      ok   (round 1 fix #5)
26  K7   bag_backup               D3 absent file             ABORT (correct: chk_file)
```

**Does each cell sit above its source of truth?** Reading the table by container:

- **K1 (3 consumers × 2 axes = 6 cells).** One sits above its source: cell 2. `bag_gpkg_refresh`
  derives its layer from `layers$geomtype` (`R/bag_gpkg_refresh.R:91-96`) — the property itself.
  `bag_gpkg_to_geojson` derives its from `layers$name` (`R/bag_gpkg_to_geojson.R:58`) — the
  container's full membership. `bag_layers` is the enumerator, so its source of truth *is*
  `st_layers()`, and NA geomtype is its documented answer; correct.
- **K2 (5 cells).** All five return; one diverges from its sibling in contract (cell 8).
- **K3 (5 cells).** Three sit above their source: cells 12–14. `bag_assign_utm` validates the
  column *values* it writes (`placed <- !is.na(epsg)`, line 126); `bag_sf_from_utm` validates
  neither the values nor the type of the column it reads, and its comment at lines 58-61 states
  the opposite case only ("tibble already reports a missing column by name").
- **K4 (6 cells).** Two sit above their source: cells 18 and 21. `.bag_crs_unusable()` exists
  and is reached from one consumer.
- **K5 (1 cell), K6/K7 (3 cells).** All on their source of truth. Cell 23 was a hypothesis I
  held and **disproved**: `names(l_raw)` on an unnamed list is NULL, `l_raw[logical(0)]` is the
  empty list, and I expected `bag_bcdc_index()` to return an empty lookup table silently. It does
  not — `dplyr::select()` aborts naming `url`. Loud, so not a finding. Recorded because a
  disproved candidate is data too.

**That is the whole set the mechanism reaches: 26 cells over 6 containers, every one executed,
4 findings, all 4 in a cell where one member of a pair handles the input and its sibling does
not.** No cell returned a silently wrong value; the three aborts and one divergence below are
the complete list.

### Two further claims checked and found sound

- `tools` and `utils` appear in `NAMESPACE` `importFrom()` but not in `DESCRIPTION` `Imports:`.
  Not a finding: `tools:::.check_package_depends("bagcopy")` returns empty — base-priority
  packages are exempt. This confirms the brief's 0 errors / 0 warnings / 0 notes.
- `bag_assign_latlong()` writing `NaN` does not reach disk as `NaN`: GDAL normalises it to SQL
  NULL on `st_write()` (measured, `typeof(a)` = `null`), and `readr::write_csv(na = "")` writes
  it as the empty field. Finding 3 is therefore scoped to the missing warning and the in-session
  value, not to the files.

---

# Part 3 — FINDINGS

### 1. **[bug]** `R/bag_gpkg_to_geojson.R:57-75` — refuses a GeoPackage carrying a QGIS `layer_styles` table, which is the documented use case round 2's fix #3 restored for the sibling

`layer_names <- layers$name` (line 58) takes **every** layer, spatial or not, and the CRS
pre-check at line 66 maps `.bag_crs_unusable()` over all of them. `sf::st_layers()` reports an
aspatial table with `crs` = `NA`, so `.bag_crs_unusable()` returns `TRUE` for it (its own first
branch, `R/bag_crs_unusable.R:21`), and the function aborts before writing anything:

```
'…/form_sites.gpkg' has 1 layer with no usable CRS: "layer_styles".
ℹ GeoJSON is WGS 84 by definition, so coordinates with no CRS cannot be written correctly.
ℹ Set a CRS on it first, with `sf::st_crs()`.
```

The remedy in that message cannot be run: there is no geometry to set a CRS on. And because the
check is deliberately up front ("a GeoPackage converts whole or not at all", line 64), a styled
GeoPackage cannot be converted **at all** — not even its good layers.

This is the same file and the same table that `R/bag_gpkg_refresh.R:85-96` was taught to skip:

> `st_layers()` also lists support tables such as QGIS's `layer_styles`, and a styled Mergin
> field form is the documented use case, so counting those refused the very files this function
> is for. The discriminator is the property itself: a support table has no geometry type.

Reproduced on both consumers over one file (cells 1 and 2): `bag_gpkg_refresh()` returns the
refreshed layer; `bag_gpkg_to_geojson()` aborts. `bag_layers()`, the third consumer, is correct
because enumerating is its job.

The fix is the discriminator already written one file away — filter `layer_names` by
`layers$geomtype` before the CRS check and before the loop, and the two consumers then share one
definition of "the layers I mean". Note the loop body at line 86 depends on this: for an
aspatial layer `sf::st_crs(d) != sf::st_crs(4326)` evaluates to `TRUE` (measured), so without the
line-66 guard the loop would reach `st_transform()` on a plain data frame — the guard is
load-bearing in exactly the wrong direction.

- **Rule:** code-check.md "A fix lands in one of two callers that share a harness" ; code-check.md "A fixture that cannot reach the failure mode" ; code-check.md "A guard's scope, escape hatches, and remedies"

### 2. **[bug]** `R/bag_sf_from_utm.R:90-101` — cannot read `bag_assign_utm()`'s own documented output, and has no guard on the zone column at all

Round 2's fix #1 gave `bag_assign_utm()` a new output shape: a row the zone arithmetic cannot
place is carried through with `utm_zone`, `easting` and `northing` set to `NA_real_`. The
documented partner for those columns is `bag_sf_from_utm()` (the two `@seealso` each other), and
`bag_gpkg_refresh()` writes that shape to the GeoPackage and to the `.csv` "versionable" backup.
Handed it back, the reader aborts from inside sf:

```r
u <- bag_assign_utm(<two points, one with an empty geometry>)   # warns, returns 3 cols of NA
bag_sf_from_utm(sf::st_drop_geometry(u))
#> Error: ℹ In index: 2.
#> Caused by error in `st_as_sf.data.frame()`:
#> ! missing values in coordinates not allowed
```

The message names a `group_split()` index — not the row, not the column, not the value — so a
caller has nothing to act on. Round 2's fix is therefore complete at the producer and absent at
the consumer; the shape it deliberately introduced is a shape the package itself cannot read
back.

The same line has no guard on the zone at all, which is the general case (cells 12–14):

| zone value | result |
|---|---|
| `NA` | `st_as_sf()`: "missing values in coordinates not allowed" (when coords are NA too), or `st_transform()`: "cannot transform sfc object with missing crs" |
| `0`, or anything outside 1–60 | `st_transform()`: "cannot transform sfc object with missing crs", preceded by a GDAL warning `crs not found: EPSG:26900` |
| `"9"` (character — which is what `readr` returns for an all-empty zone column) | `26900 + unique(.x[[col_utm_zone]])`: "non-numeric argument to binary operator" |

The comment at lines 58-61 explains why there is no guard — "tibble already reports a missing
column by name […] the guard changed nothing a caller could observe". That reasoning is sound
for an **absent column** and says nothing about an invalid **value**, which is the case the
sibling now produces. A comment worded more narrowly than the code reaches is true only of the
case it names.

Decide what the contract is — drop unplaceable rows with a warning, or carry them with empty
geometry — and then validate `dat[[col_utm_zone]]` against it before the pipeline, so the
message names the rows and the column rather than an index. The round-trip test at
`tests/testthat/test-bag_sf_from_utm.R:85` is the right place to pin it, with an unplaceable row
added to its fixture.

- **Rule:** code-check.md "A fix lands in one of two callers that share a harness" ; code-check.md "A guard's scope, escape hatches, and remedies" ; code-check.md "Written data outlives the fix"

### 3. **[fragile]** `R/bag_assign_latlong.R:47-54` — the sibling assigner is silent on the row round 2's fix #1 decided was worth warning about, and writes `NaN` where the other writes `NA_real_`

Both coordinate assigners take an `sf` POINT layer and write columns read off
`sf::st_coordinates()`. For a feature with an empty geometry, `st_coordinates()` returns an
`NA` row (sf 1.1.2), so neither function drops the row — but their contracts diverge:

| | `bag_assign_utm` | `bag_assign_latlong` |
|---|---|---|
| unplaceable row | warned (`cli_warn`, lines 140-148) | silent |
| value written | `NA_real_` (lines 101-105) | `NaN` |
| documented | yes, `@return` and prose | no |

`bag_assign_utm.R:97-99` states the reason for the second row explicitly — "NaN is an NA in R,
but it prints differently and would read as a computed value rather than a missing one" — and
`bag_assign_latlong()` leaves exactly that NaN in `lon` and `lat`. The missing warning is the
substantive half: round 2's fix decided a caller must be told when a row has no usable
coordinates, and the sibling produces the same row for the same reason without saying so.

Scope, measured and stated honestly: `NaN` does **not** reach disk differently — GDAL writes it
as SQL NULL and `readr::write_csv(na = "")` as an empty field — and `is.na(NaN)` is `TRUE`, so a
caller testing for missingness is unaffected. What is affected is a caller who prints the frame,
or who tests `identical(x, NA_real_)`, and every caller who would have acted on the warning.

- **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

### 4. **[fragile]** `R/bag_gpkg_refresh.R:107` — `.bag_crs_unusable()` is reached from one of the two GeoPackage CRS consumers, so `bag_gpkg_refresh()` takes an `srs_id` 0 layer's coordinates for WGS 84

Round 2's fix #2 established the property and wrote the helper. Its own roxygen states the
hazard:

> `0` ("undefined geographic") becomes a `GEOGCRS` that transforms without complaint, silently
> taking the coordinates for WGS 84.

`bag_gpkg_refresh()` reads a layer (line 107) and hands it to `bag_assign_utm()`, which does
`sf::st_transform(dat, crs = 4326)` (line 79) — the exact transform the helper exists to refuse —
without consulting it. Over the same file, the two consumers answer differently (cells 17–22):

| `srs_id` | `bag_gpkg_to_geojson` | `bag_gpkg_refresh` |
|---|---|---|
| 0 | aborts, naming the layer and the remedy | **proceeds**, coordinates taken for lon/lat |
| −1 | aborts, naming the layer and the remedy | aborts from GDAL: `OGRCreateCoordinateTransformation(): transformation not available` — naming neither the layer nor the CRS |

I probed for silent corruption on disk and **did not find it**, which bounds this finding. For a
layer whose stored coordinates genuinely are degrees, the result is right by luck. For a
projected layer wrongly declared `srs_id` 0 the zone arithmetic produces a nonsense zone and the
call aborts (`crs not found: is it missing?`) — and it aborts at the UTM step, which is *before*
the `write_back_to_path` write at line 134, so the GeoPackage is not rewritten. So the cost here
is an unactionable message and a lost guarantee, not corrupted data. It is filed because it is
the fourth instance of the mechanism and the cheapest to close: one `.bag_crs_unusable()` call
after line 107.

- **Rule:** code-check.md "A fix lands in one of two callers that share a harness" ; code-check.md "A proxy is not the property"

---

## What would terminate this class

Not another round. Two mechanical checks, both of which this round's enumeration already runs
once and neither of which is wired into the suite:

1. **A fixture shared across a container's consumers.** Move the `layer_styles` builder from
   `test-bag_gpkg_refresh.R:333-345` into `tests/testthat/helper-*.R`, and require every K1
   consumer to have a test using it. The same for the unplaceable row across K2 and K3.
2. **The contract diff as a test.** The 26-cell matrix is a test: for each container, run every
   consumer over every axis and assert the verdicts agree where the container's property says
   they must. A new export over an existing container then has to declare its row.
