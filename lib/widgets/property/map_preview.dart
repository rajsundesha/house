import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location/map_service.dart';

class MapPreview extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng)? onLocationSelected;
  final bool interactive;

  const MapPreview({
    Key? key,
    this.initialLocation,
    this.onLocationSelected,
    this.interactive = true,
  }) : super(key: key);

  @override
  _MapPreviewState createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final _mapService = MapService();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('selected'),
          position: widget.initialLocation!,
          draggable: widget.interactive,
          onDragEnd: widget.onLocationSelected,
        ),
      );
    }
  }

  void _handleMapTap(LatLng location) {
    if (!widget.interactive) return;

    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId('selected'),
          position: location,
          draggable: true,
          onDragEnd: widget.onLocationSelected,
        ),
      };
    });

    widget.onLocationSelected?.call(location);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialLocation ?? LatLng(20.5937, 78.9629),
            zoom: 15,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: _markers,
          onTap: _handleMapTap,
          myLocationEnabled: widget.interactive,
          myLocationButtonEnabled: widget.interactive,
          zoomControlsEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          scrollGesturesEnabled: widget.interactive,
          rotateGesturesEnabled: widget.interactive,
          tiltGesturesEnabled: widget.interactive,
        ),
      ),
    );
  }
}
