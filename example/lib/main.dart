import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nicetables/nicetables.dart';

void main() => runApp(const GalleryApp());

/// Gallery for nicetables: a transactions table with every feature on, a
/// server-side async table, and a card-layout preview.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF06102A); // navy, matching the custodian portal
    return MaterialApp(
      title: 'nicetables gallery',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          primary: const Color(0xFF60A5FA),
          surface: const Color(0xFF0B1220),
        ),
        scaffoldBackgroundColor: const Color(0xFF060B16),
      ),
      home: GalleryPage(
        mode: _mode,
        onToggleMode: () => setState(
          () => _mode =
              _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo data
// ---------------------------------------------------------------------------

enum TxStatus { approved, pending, rejected, processing, archived }

class Transaction {
  const Transaction({
    required this.id,
    required this.customer,
    required this.email,
    required this.asset,
    required this.amount,
    required this.fee,
    required this.status,
    required this.createdAt,
    required this.progress,
    required this.verified,
  });

  final String id;
  final String customer;
  final String email;
  final String asset;
  final double amount;
  final double fee;
  final TxStatus status;
  final DateTime createdAt;
  final double progress;
  final bool verified;

  NiceStatusValue get statusValue => switch (status) {
        TxStatus.approved =>
          const NiceStatusValue('Approved', NiceStatus.success),
        TxStatus.pending =>
          const NiceStatusValue('Pending', NiceStatus.warning),
        TxStatus.rejected =>
          const NiceStatusValue('Rejected', NiceStatus.error),
        TxStatus.processing =>
          const NiceStatusValue('Processing', NiceStatus.info),
        TxStatus.archived =>
          const NiceStatusValue('Archived', NiceStatus.neutral),
      };
}

List<Transaction> generateTransactions(int count, {int seed = 7}) {
  final rnd = Random(seed);
  const first = [
    'Amara',
    'Bruno',
    'Chloé',
    'Dmitri',
    'Esther',
    'Farid',
    'Grace',
    'Hugo',
    'Imani',
    'Jonas',
    'Keiko',
    'Luca',
    'Maya',
    'Noah',
    'Olivia',
    'Pavel',
    'Quinn',
    'Rosa',
    'Samir',
    'Tove',
    'Uma',
    'Viktor',
    'Wren',
    'Yara',
    'Zane',
  ];
  const last = [
    'Okafor',
    'Silva',
    'Martin',
    'Volkov',
    'Cohen',
    'Haddad',
    'Nakamura',
    'Rossi',
    'Mensah',
    'Berg',
    'Dubois',
    'Khan',
    'Novak',
    'Osei',
    'Petrov',
  ];
  const assets = ['BTC', 'ETH', 'USDC', 'SOL', 'XRP', 'ADA'];
  final now = DateTime(2026, 11, 3, 14, 30);
  return List.generate(count, (i) {
    final name = '${first[rnd.nextInt(first.length)]} '
        '${last[rnd.nextInt(last.length)]}';
    final status = TxStatus.values[rnd.nextInt(TxStatus.values.length)];
    final amount = (rnd.nextDouble() * 50000).roundToDouble() / 1 + 0.5;
    return Transaction(
      id: 'TX-${(100000 + i * 7919 % 899999).toString().padLeft(6, '0')}',
      customer: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
      asset: assets[rnd.nextInt(assets.length)],
      amount: amount,
      fee: (amount * 0.0025 * 100).round() / 100,
      status: status,
      createdAt: now.subtract(Duration(minutes: rnd.nextInt(60 * 24 * 40))),
      progress: switch (status) {
        TxStatus.approved => 1,
        TxStatus.rejected => 0,
        TxStatus.archived => 1,
        _ => rnd.nextDouble(),
      },
      verified: rnd.nextInt(4) != 0,
    );
  });
}

// ---------------------------------------------------------------------------
// Gallery
// ---------------------------------------------------------------------------

class GalleryPage extends StatefulWidget {
  const GalleryPage(
      {required this.mode, required this.onToggleMode, super.key});

  final ThemeMode mode;
  final VoidCallback onToggleMode;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final _rows = generateTransactions(240);
  final _controller = NiceTableController<Transaction>(
    sort: const NiceSort('created', NiceSortDirection.descending),
  );
  int _tab = 0;
  bool _stripes = false;
  bool _pinned = true;
  bool _expandable = true;
  NiceSelectionMode _selection = NiceSelectionMode.multi;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<NiceColumn<Transaction>> get _columns => [
        NiceColumn.text(
          'id',
          'Transaction',
          (t) => t.id,
          mono: true,
          width: const NiceColumnWidth.fixed(132),
          primary: true,
        ),
        NiceColumn.custom(
          'customer',
          'Customer',
          (context, t, _) =>
              NiceAvatarCell(name: t.customer, subtitle: t.email),
          value: (t) => t.customer,
          width: const NiceColumnWidth.flex(2, min: 200),
        ),
        NiceColumn.status(
          'status',
          'Status',
          (t) => t.statusValue,
          filterOptions: const [],
        ),
        NiceColumn.text(
          'asset',
          'Asset',
          (t) => t.asset,
          width: const NiceColumnWidth.fixed(112),
          filterOptions: const [],
        ),
        NiceColumn.money('amount', 'Amount', (t) => t.amount),
        NiceColumn.money('fee', 'Fee', (t) => t.fee, visible: false),
        NiceColumn.custom(
          'progress',
          'Progress',
          (context, t, _) => NiceProgressCell(t.progress),
          value: (t) => t.progress,
          width: const NiceColumnWidth.flex(1, min: 140),
          searchable: false,
        ),
        NiceColumn.boolean('verified', 'Verified', (t) => t.verified),
        NiceColumn.date(
          'created',
          'Created',
          (t) => t.createdAt,
          format: (d) => NiceFormat.relative(d, now: DateTime(2026, 11, 3, 15)),
        ),
        NiceColumn.actions(
          'actions',
          (context, t, _) => NiceRowActions(
            inlineCount: 1,
            actions: [
              NiceAction(
                label: 'View',
                icon: Icons.open_in_new_rounded,
                onPressed: () => _toast('Open ${t.id}'),
              ),
              NiceAction(
                label: 'Copy id',
                icon: Icons.copy_rounded,
                onPressed: () => _toast('Copied ${t.id}'),
              ),
              NiceAction(
                label: 'Reject',
                icon: Icons.block_rounded,
                destructive: true,
                enabled: t.status == TxStatus.pending,
                onPressed: () => _toast('Rejected ${t.id}'),
              ),
            ],
          ),
          width: 88,
        ),
      ];

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wraps onto two lines on narrow windows instead of overflowing.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'nicetables',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                      ),
                      const SizedBox(width: 20),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Transactions')),
                          ButtonSegment(value: 1, label: Text('Server-side')),
                          ButtonSegment(value: 2, label: Text('Cards')),
                        ],
                        selected: {_tab},
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (s) =>
                            setState(() => _tab = s.first),
                      ),
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_tab == 0) ...[
                        _Toggle(
                          label: 'Stripes',
                          value: _stripes,
                          onChanged: (v) => setState(() => _stripes = v),
                        ),
                        _Toggle(
                          label: 'Pinned',
                          value: _pinned,
                          onChanged: (v) => setState(() => _pinned = v),
                        ),
                        _Toggle(
                          label: 'Expandable',
                          value: _expandable,
                          onChanged: (v) => setState(() => _expandable = v),
                        ),
                        _Toggle(
                          label: 'Multi-select',
                          value: _selection == NiceSelectionMode.multi,
                          onChanged: (v) => setState(
                            () => _selection = v
                                ? NiceSelectionMode.multi
                                : NiceSelectionMode.single,
                          ),
                        ),
                      ],
                      IconButton(
                        tooltip: 'Toggle dark mode',
                        onPressed: widget.onToggleMode,
                        icon: Icon(
                          widget.mode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: switch (_tab) {
                  0 => _transactionsTable(),
                  1 => _serverTable(),
                  _ => _cardsPreview(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionsTable() => NiceTable<Transaction>(
        key: const ValueKey('transactions'),
        title: 'Transactions',
        rows: _rows,
        columns: _columns,
        controller: _controller,
        rowKey: (t) => t.id,
        rowLabel: 'transactions',
        selectionMode: _selection,
        showDensityToggle: true,
        showExport: true,
        pinnedColumns: _pinned ? 2 : 0,
        expandedBuilder: _expandable ? _detail : null,
        theme: NiceTableTheme.of(context).copyWith(showStripes: _stripes),
        onRefresh: () => _toast('Refreshed'),
        onRowTap: (t) => _toast('Tapped ${t.id}'),
        onRowSecondaryTap: (t, pos) => _toast('Context menu for ${t.id}'),
        rowStyle: (t) {
          if (t.status != TxStatus.rejected) return null;
          final bg = NiceTableTheme.of(context).statusPalette.error.background;
          return NiceRowStyle(background: bg.withValues(alpha: bg.a * 0.4));
        },
        actions: [
          FilledButton.icon(
            onPressed: () => _toast('New transaction'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
          ),
        ],
        bulkActions: (context, selected) => [
          TextButton.icon(
            onPressed: () => _toast('Approved ${selected.length}'),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
          ),
          TextButton.icon(
            onPressed: () => _toast('Exported ${selected.length}'),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Export'),
          ),
        ],
      );

  Widget _detail(BuildContext context, Transaction t) {
    final theme = NiceTableTheme.of(context);
    Widget item(String label, String value) => Padding(
          padding: const EdgeInsets.only(right: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(), style: theme.headerTextStyle),
              const SizedBox(height: 4),
              Text(value, style: theme.cellTextStyle),
            ],
          ),
        );
    return Wrap(
      runSpacing: 12,
      children: [
        item('Customer email', t.email),
        item('Created', NiceFormat.dateTime(t.createdAt)),
        item('Fee', NiceFormat.number(t.fee, decimals: 2)),
        item('Net', NiceFormat.number(t.amount - t.fee, decimals: 2)),
        SizedBox(
          width: 320,
          child: NiceCopyableText(
            'sha256:${t.id.hashCode.toRadixString(16).padLeft(8, '0')}'
            'e3b0c44298fc1c149afbf4c8996fb924',
          ),
        ),
      ],
    );
  }

  Widget _serverTable() => NiceAsyncTable<Transaction>(
        key: const ValueKey('server'),
        title: 'Server-side paging',
        subtitle: 'Each page is fetched with a simulated 600 ms latency',
        rowLabel: 'transactions',
        fetch: _fakeFetch,
        rowKey: (t) => t.id,
        selectionMode: NiceSelectionMode.multi,
        onRowTap: (t) => _toast('Tapped ${t.id}'),
        columns: [
          NiceColumn.text('id', 'Transaction', (t) => t.id, mono: true),
          NiceColumn.text('customer', 'Customer', (t) => t.customer,
              subtitle: (t) => t.email),
          NiceColumn.status('status', 'Status', (t) => t.statusValue),
          NiceColumn.money('amount', 'Amount', (t) => t.amount),
          NiceColumn.date('created', 'Created', (t) => t.createdAt),
        ],
      );

  Future<NicePage<Transaction>> _fakeFetch(NiceQuery<Transaction> q) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (q.search == 'fail') throw Exception('The server said no.');
    // A real backend would translate [q]; here we reuse the client
    // pipeline on a private controller to produce the page.
    final c = NiceTableController<Transaction>(
      sort: q.sort,
      search: q.search,
      filters: q.filters,
      page: q.page,
      pageSize: q.pageSize,
    );
    final result = c.process(_rows, _columns);
    c.dispose();
    return NicePage(rows: result.pageRows, total: result.total);
  }

  Widget _cardsPreview() => Center(
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 6,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: NiceTable<Transaction>(
            key: const ValueKey('cards'),
            title: 'Transactions',
            rows: _rows,
            columns: _columns,
            rowKey: (t) => t.id,
            rowLabel: 'transactions',
            selectionMode: NiceSelectionMode.multi,
            pageSizeOptions: const [10, 25],
            theme: NiceTableTheme.of(context).copyWith(
              borderRadius: BorderRadius.zero,
              showBorder: false,
            ),
            onRowTap: (t) => _toast('Tapped ${t.id}'),
          ),
        ),
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 4),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}
