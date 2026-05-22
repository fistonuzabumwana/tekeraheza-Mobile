import 'package:flutter/material.dart';

import '../di/service_locator.dart';
import '../../services/location_service.dart';

class LocationValues {
  const LocationValues({
    this.province,
    this.district,
    this.sector,
    this.cell,
    this.village,
  });

  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;

  LocationValues copyWith({
    String? province,
    String? district,
    String? sector,
    String? cell,
    String? village,
  }) {
    return LocationValues(
      province: province ?? this.province,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
      village: village ?? this.village,
    );
  }
}

class LocationSelector extends StatefulWidget {
  const LocationSelector({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });

  final LocationValues values;
  final ValueChanged<LocationValues> onChanged;
  final bool enabled;

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final _svc = sl<LocationService>();

  List<String> _provinces = const [];
  List<String> _districts = const [];
  List<String> _sectors = const [];
  List<String> _cells = const [];
  List<String> _villages = const [];

  bool _loadingProvinces = false;
  bool _loadingDistricts = false;
  bool _loadingSectors = false;
  bool _loadingCells = false;
  bool _loadingVillages = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final p = await _svc.getProvinces();
      if (!mounted) return;
      setState(() => _provinces = p);
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadDistricts(String province) async {
    setState(() {
      _loadingDistricts = true;
      _districts = const [];
      _sectors = const [];
      _cells = const [];
      _villages = const [];
    });
    try {
      final d = await _svc.getDistricts(province);
      if (!mounted) return;
      setState(() => _districts = d);
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadSectors(String district) async {
    setState(() {
      _loadingSectors = true;
      _sectors = const [];
      _cells = const [];
      _villages = const [];
    });
    try {
      final s = await _svc.getSectors(district);
      if (!mounted) return;
      setState(() => _sectors = s);
    } finally {
      if (mounted) setState(() => _loadingSectors = false);
    }
  }

  Future<void> _loadCells(String sector) async {
    setState(() {
      _loadingCells = true;
      _cells = const [];
      _villages = const [];
    });
    try {
      final c = await _svc.getCells(sector);
      if (!mounted) return;
      setState(() => _cells = c);
    } finally {
      if (mounted) setState(() => _loadingCells = false);
    }
  }

  Future<void> _loadVillages(String cell) async {
    setState(() {
      _loadingVillages = true;
      _villages = const [];
    });
    try {
      final v = await _svc.getVillages(cell);
      if (!mounted) return;
      setState(() => _villages = v);
    } finally {
      if (mounted) setState(() => _loadingVillages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final values = widget.values;

    InputDecoration deco(String label, {bool loading = false}) {
      return InputDecoration(
        labelText: label,
        suffixIcon: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: (values.province?.isNotEmpty ?? false) ? values.province : null,
          decoration: deco('Province', loading: _loadingProvinces),
          items: _provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: !enabled
              ? null
              : (v) {
                  final next = LocationValues(province: v);
                  widget.onChanged(next);
                  if (v != null) _loadDistricts(v);
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value:
              (values.district?.isNotEmpty ?? false) ? values.district : null,
          decoration: deco('District', loading: _loadingDistricts),
          items: _districts
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (!enabled || values.province == null || values.province == '')
              ? null
              : (v) {
                  final next = values.copyWith(
                    district: v,
                    sector: null,
                    cell: null,
                    village: null,
                  );
                  widget.onChanged(next);
                  if (v != null) _loadSectors(v);
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: (values.sector?.isNotEmpty ?? false) ? values.sector : null,
          decoration: deco('Sector', loading: _loadingSectors),
          items: _sectors
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (!enabled || values.district == null || values.district == '')
              ? null
              : (v) {
                  final next = values.copyWith(
                    sector: v,
                    cell: null,
                    village: null,
                  );
                  widget.onChanged(next);
                  if (v != null) _loadCells(v);
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: (values.cell?.isNotEmpty ?? false) ? values.cell : null,
          decoration: deco('Cell', loading: _loadingCells),
          items: _cells
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (!enabled || values.sector == null || values.sector == '')
              ? null
              : (v) {
                  final next = values.copyWith(cell: v, village: null);
                  widget.onChanged(next);
                  if (v != null) _loadVillages(v);
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: (values.village?.isNotEmpty ?? false) ? values.village : null,
          decoration: deco('Village', loading: _loadingVillages),
          items: _villages
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (!enabled || values.cell == null || values.cell == '')
              ? null
              : (v) => widget.onChanged(values.copyWith(village: v)),
        ),
      ],
    );
  }
}

