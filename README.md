# nicetables

Beautiful, feature-complete data tables for Flutter, with gorgeous defaults.

One typed column definition drives everything: sorting, search, filtering,
export and the responsive card layout all come from a single `value`
callback per column, so a production table is a few lines, not a
`DataTableSource` subclass and a pile of `_sortBy` switches.

```dart
import 'package:nicetables/nicetables.dart';

NiceTable<Order>(
  title: 'Orders',
  rows: orders,
  columns: [
    NiceColumn.text('id', 'Order', (o) => o.id, mono: true),
    NiceColumn.text('customer', 'Customer', (o) => o.customer),
    NiceColumn.status('status', 'Status', (o) => o.statusValue),
    NiceColumn.money('total', 'Total', (o) => o.total),
    NiceColumn.date('placed', 'Placed', (o) => o.placedAt),
  ],
  selectionMode: NiceSelectionMode.multi,
  onRowTap: openOrder,
)
```

That gives you a sticky header, sortable columns, a debounced search box,
per-column filter menus, a pagination footer, a checkbox column with
shift-click ranges and a bulk-action bar, hover and focus states, keyboard
navigation, a column picker, an empty state, and a card layout under 600 px.
Dark mode and brand colours come from `Theme.of(context)` with no setup.

## Features

- **Pure Flutter.** No native code, no third-party dependencies beyond
  `meta`. Web, desktop and mobile.
- **Typed columns.** `NiceColumn.text / number / money / date / status /
  boolean / actions / custom`, each with a `value` callback. Width policy
  per column (`flex` with a minimum, or `fixed`).
- **One controller.** `NiceTableController` owns sort, search, filters,
  page, selection, expansion, column visibility, column widths, density
  and keyboard focus. Pass your own to read or drive it; omit it and the
  table makes one.
- **Client or server processing.** Client side is automatic and cached.
  For a backend, use `NiceAsyncTable` with a `fetch(NiceQuery)` callback
  and get loading, error, retry and out-of-order protection for free.
- **Toolbar.** Title and live row count, search, your action buttons,
  active-filter chips with "Clear all", a column picker, a density menu,
  CSV export and refresh. While rows are selected the title becomes a
  bulk bar: "12 selected", "Select all 1,204", your bulk actions, clear.
- **Rows.** Hover, selected, focused and striped states; per-row style
  overrides; tap, double tap and right-click / long-press callbacks;
  expandable detail panels with animation.
- **Columns.** Pinned leading columns with a scroll shadow, drag-to-resize
  handles (double-click resets), show/hide, filter menus derived from the
  data or supplied explicitly.
- **Keyboard.** Arrow keys, Home/End, PageUp/PageDown, Space to select,
  Enter to open, Left/Right to collapse/expand, Ctrl/Cmd+A, Escape.
- **Cells.** `NiceStatusChip`, `NiceAvatarCell`, `NiceMonoText`,
  `NiceCopyableText`, `NiceProgressCell`, `NiceTrendCell`,
  `NiceRowActions` (inline icons plus an overflow menu).
- **States.** Pulsing skeleton rows on first load, a slim progress bar
  while refreshing, friendly empty and "no matches" states, an error state
  with retry.
- **Responsive.** Below `compactBreakpoint` rows become cards (primary
  column as title, status chips and actions in the card header, the rest
  as a key/value list). Toolbar and footer adapt to narrow widths.
- **Theme.** `NiceTableTheme` derives from your `ColorScheme` and
  `TextTheme`, flips with dark mode, and is a `ThemeExtension`, so you can
  register one app-wide or scope one with `NiceTableThemeScope`.
- **Accessible.** Semantic labels on sort buttons, checkboxes and rows;
  status chips announce their state; contrast-checked status palettes;
  reduced-motion aware skeletons.

## Installation

```bash
flutter pub add nicetables
```

Requires Flutter 3.27 or newer. No other dependencies.

## Usage

### Columns

```dart
NiceColumn.text('name', 'Name', (r) => r.name,
    subtitle: (r) => r.email, primary: true)
NiceColumn.number('qty', 'Quantity', (r) => r.qty, decimals: 0)
NiceColumn.money('total', 'Total', (r) => r.total, symbol: '€')
NiceColumn.date('created', 'Created', (r) => r.createdAt,
    format: NiceFormat.relative)
NiceColumn.status('status', 'Status', (r) => r.statusValue,
    filterOptions: const []) // [] = derive the menu from the data
NiceColumn.boolean('kyc', 'KYC', (r) => r.verified)
NiceColumn.custom('owner', 'Owner',
    (context, r, cell) => NiceAvatarCell(name: r.owner, subtitle: r.role),
    value: (r) => r.owner)
NiceColumn.actions('actions', (context, r, cell) => NiceRowActions(
  inlineCount: 1,
  actions: [
    NiceAction(label: 'Open', icon: Icons.open_in_new, onPressed: () {}),
    NiceAction(label: 'Delete', icon: Icons.delete_outline,
        destructive: true, onPressed: () {}),
  ],
))
```

A status value is a label plus a semantic colour:

```dart
NiceStatusValue get statusValue => switch (status) {
  OrderStatus.paid => const NiceStatusValue('Paid', NiceStatus.success),
  OrderStatus.pending => const NiceStatusValue('Pending', NiceStatus.warning),
  OrderStatus.failed => const NiceStatusValue('Failed', NiceStatus.error),
};
```

### Controller

```dart
final controller = NiceTableController<Order>(
  sort: const NiceSort('placed', NiceSortDirection.descending),
  pageSize: 50,
);

controller.setSearch('okafor');
controller.setFilter('status',
    NiceFilter.oneOf(values: {'Paid'}, valueOf: (o) => o.statusValue.label));
controller.selectedKeys;      // Set<Object>
controller.query;             // NiceQuery: sort, search, filters, page
controller.addListener(() {}); // it is a ChangeNotifier
```

Riverpod, Bloc or plain `setState` can all own the controller; the table
only needs a reference.

### Server-side data

```dart
NiceAsyncTable<Order>(
  fetch: (q) async {
    final page = await api.orders(
      offset: q.offset,
      limit: q.pageSize,
      sortBy: q.sort?.columnId,
      descending: q.sort?.ascending == false,
      search: q.search,
      status: q.filters['status']?.value,
    );
    return NicePage(rows: page.items, total: page.total);
  },
  columns: columns,
)
```

Or keep `NiceTable` and set `processing: NiceProcessing.server`,
`totalRows`, `loading`, `error` and `onQueryChanged` yourself.

### Selection and bulk actions

```dart
NiceTable<Order>(
  selectionMode: NiceSelectionMode.multi,
  rowKey: (o) => o.id,             // stable identity for selection
  onSelectionChanged: (rows) {},
  bulkActions: (context, selected) => [
    TextButton.icon(
      onPressed: () => approve(selected),
      icon: const Icon(Icons.check),
      label: const Text('Approve'),
    ),
  ],
)
```

### Expandable rows, pinned and resizable columns

```dart
NiceTable<Order>(
  pinnedColumns: 2,
  resizableColumns: true,
  expandedBuilder: (context, o) => OrderDetail(o),
)
```

### Theming

```dart
// App-wide, via ThemeExtension:
ThemeData(
  extensions: [
    NiceTableTheme.fromColorScheme(scheme).copyWith(
      showStripes: true,
      density: NiceDensity.compact,
      borderRadius: BorderRadius.circular(8),
    ),
  ],
)

// Per subtree:
NiceTableThemeScope(theme: myTableTheme, child: ...)

// Per table:
NiceTable(theme: NiceTableTheme.of(context).copyWith(showBorder: false))
```

Everything is a slot: header and surface colours, hover / selected /
stripe tints, dividers, focus ring, text styles (cell, subtitle, mono),
status palette, radius, paddings, density and the hover animation
duration.

### Layout

Give the table a bounded height (`Expanded`, `SizedBox`) and rows scroll
under a sticky header. Give it none (inside a `SingleChildScrollView`) and
it sizes to its rows. Columns that do not fit scroll horizontally; pinned
columns stay put.

### Export

```dart
NiceTable(showExport: true)                          // copies CSV to clipboard
NiceTable(onExport: (csv) => saveFile('orders.csv', csv))
NiceCsv.encode(rows, columns)                        // or do it yourself
```

## Example

The `example/` app is a gallery: a transactions table with every feature
toggled on, a simulated server-side table with latency and a failing
query, and a phone-width card preview. Run it with
`cd example && flutter run -d chrome`.

## License

MIT
