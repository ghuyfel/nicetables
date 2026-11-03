# CLAUDE.md — nicetables

Flutter package of feature-complete data tables, built to replace
`data_table_2` in the custodian portal (`../frontend-portal-custodian`). It
follows the sibling `nichart` package's layout: `lib/nicetables.dart` barrel,
`lib/src/` by concern, strict lints with `public_member_api_docs`, an
`example/` gallery and tests under `test/`.

## Git conventions (same as the custodian portal)

**Branches** are `<type>/<kebab-case-slug>` off `main`, merged back with a
pull request. Types in use: `feature`, `bugfix`, `fix`, `refactor`, `chore`,
`docs`, `performance`, `release`. Example: `feature/column-reordering`,
`bugfix/footer-overflow-at-700px`.

**Commit subjects** are `<branch> : <type>(<scope>): <what is now true>`:

```
feature/global-search : feat(search): the title bar's search finds employees, clients and accounts
bugfix/footer-overflow : fix(footer): the labels drop in three tiers instead of overflowing
feature/app-error-log : style(appbar): squircle avatar on the account menu's items
```

- `<branch>` is the full branch name, then ` : ` (space, colon, space).
- `<type>` is one of `feat`, `fix`, `refactor`, `chore`, `docs`, `style`,
  `perf`, `test`, `revert`, `build`.
- `<scope>` is the area touched (`table`, `toolbar`, `footer`, `cells`,
  `theme`, `controller`, `example`, `repo`, `release`).
- The description is lower case, no trailing period, and states the
  resulting behaviour rather than the activity ("the labels drop in three
  tiers", not "fix footer"). Two clauses may be joined with `;`. Subjects
  run long (around 100 characters is normal) rather than terse.

**Commit bodies** are prose paragraphs, wrapped at about 72 columns: what
was wrong or missing, what the code does now, and where (class and folder
names in plain text). No bullet lists, no attribution trailers (see
`~/.claude/CLAUDE.md`).

**Merges** are pull requests into `main` with the branch deleted after.
