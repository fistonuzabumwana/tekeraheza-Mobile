import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPinPickerResult {
  const MapPinPickerResult(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class MapPinPickerScreen extends StatefulWidget {
  const MapPinPickerScreen({
    super.key,
    this.initial,
  });

  final LatLng? initial;

  @override
  State<MapPinPickerScreen> createState() => _MapPinPickerScreenState();
}

class _MapPinPickerScreenState extends State<MapPinPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? const LatLng(-1.9441, 30.0619); // Kigali
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                MapPinPickerResult(_selected.latitude, _selected.longitude),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _selected, zoom: 14),
        onMapCreated: (c) => _controller = c,
        onTap: (pos) {
          setState(() => _selected = pos);
          _controller?.animateCamera(CameraUpdate.newLatLng(pos));
        },
        markers: {
          Marker(
            markerId: const MarkerId('selected'),
            position: _selected,
            draggable: true,
            onDragEnd: (pos) => setState(() => _selected = pos),
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}

