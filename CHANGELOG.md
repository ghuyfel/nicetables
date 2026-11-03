## 1.1.0

- `NiceTableStrings`: every piece of text a table draws itself (search
  placeholder, footer labels and tooltips, column picker, density menu,
  export and refresh tooltips, empty, no-match and error states, the
  boolean cell's yes/no, copy and row-action tooltips) in one object,
  English by default. Pass one to `NiceTable.strings` or
  `NiceAsyncTable.strings`, or wrap the app in a `NiceTableStringsScope`
  to translate every table at once; the table argument wins over the
  scope. Counts reach the function-typed fields as numbers so a
  translation can order and format them.
- `NiceTable.searchHint`, `emptyTitle` and `rowLabel` (and the same on
  `NiceAsyncTable`) are now nullable and default to the strings; passing
  them still overrides. `NiceEmptyState.title` and `NiceErrorState.title`
  likewise. `NiceColumn.displayText` takes an optional `strings` for the
  boolean text.

## 1.0.0

First stable release.

- `NiceTable` and `NiceAsyncTable`: typed `NiceColumn` definitions whose
  single `value` callback drives sorting, search, filter menus, CSV export
  and the responsive card layout; one optional `NiceTableController` for
  sort, search, filters, page, selection, expansion, column visibility and
  widths, density and keyboard focus; client-side processing with caching,
  or server-side paging through a `fetch(NiceQuery)` callback with loading,
  error and retry states.
- Toolbar with title and live row count, debounced search, custom actions,
  active-filter chips, column picker, density menu, CSV export and refresh;
  a full-width bulk bar with "Select all N" while rows are selected.
- Footer with rows-per-page picker, row range and selection count, numbered
  page buttons with the current page highlighted and ellipses on long
  ranges, first / previous / next / last, and a "Go to" page field; adapts
  across three widths.
- Rows: hover, selected, focused and striped states, per-row style
  overrides, tap, double tap and right-click / long-press callbacks,
  animated expandable detail panels.
- Columns: flex and fixed widths, pinned leading columns with a scroll
  shadow, drag-to-resize handles, show and hide, filter menus derived from
  the data or supplied explicitly.
- Keyboard navigation: arrows, Home / End, Page Up / Down, Space, Enter,
  Left / Right to collapse and expand, Ctrl / Cmd + A, Escape.
- Cells: `NiceStatusChip`, `NiceAvatarCell`, `NiceMonoText`,
  `NiceCopyableText`, `NiceProgressCell`, `NiceTrendCell`,
  `NiceRowActions`.
- States: pulsing skeleton rows, a slim progress bar while refreshing,
  empty and "no matches" states, error state with retry.
- `NiceTableTheme` derived from the app `ColorScheme` and `TextTheme`,
  dark-mode aware, registrable as a `ThemeExtension` or scoped with
  `NiceTableThemeScope`; contrast-checked status palettes.
- Every built-in control fits all three densities; row actions, the bulk
  bar and the footer degrade gracefully instead of overflowing.
