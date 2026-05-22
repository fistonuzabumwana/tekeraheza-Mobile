import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mobile_shell.dart';

typedef ItemBuilder = Widget Function(BuildContext context, int index);

class DataListScreen extends StatefulWidget {
  const DataListScreen({
    super.key,
    required this.title,
    required this.loadPage,
    required this.itemBuilder,
    this.searchable = true,
    this.fab,
    this.onRefresh,
  });

  final String title;
  final Future<List<Map<String, dynamic>>> Function(int page, String? query)
      loadPage;
  final Widget Function(Map<String, dynamic> item) itemBuilder;
  final bool searchable;
  final Widget? fab;
  final Future<void> Function()? onRefresh;

  @override
  State<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  final _items = <Map<String, dynamic>>[];
  final _scroll = ScrollController();
  final _search = TextEditingController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 0;
      _hasMore = true;
      _items.clear();
    }
    if (!_hasMore && !reset) return;

    setState(() {
      _error = null;
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final batch = await widget.loadPage(
        _page,
        widget.searchable && _search.text.isNotEmpty ? _search.text : null,
      );
      setState(() {
        if (reset) _items.clear();
        _items.addAll(batch);
        _hasMore = batch.length >= 20;
        if (batch.isNotEmpty) _page++;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: widget.title,
      floatingActionButton: widget.fab,
      child: Column(
        children: [
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      _load(reset: true);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                onSubmitted: (_) => _load(reset: true),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _load(reset: true);
                await widget.onRefresh?.call();
              },
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _load(reset: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              'No items found',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(_items[index]);
      },
    );
  }
}
