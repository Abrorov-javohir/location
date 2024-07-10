import 'package:dars13/service/location_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  LocationData? myLocation;
  Location location = Location();

  LatLng najotTalim = const LatLng(41.2856806, 69.2034646);
  LatLng najotTalimOldidagiMagazin = const LatLng(41.2856806, 69.2045946);
  LatLng? meningJoylashuvim;
  List<LatLng> myPositions = [];
  Set<Marker> myMarkers = {};
  Set<Polyline> polylines = {};
  MapType currentMapType = MapType.normal;
  LatLng? selectedLocation;

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getUserLocation();
  }

  void onCameraMove(CameraPosition position) {
    meningJoylashuvim = position.target;
    _updateMyLocationMarker();
  }

  void _updateMyLocationMarker() {
    setState(() {
      myMarkers.removeWhere(
          (marker) => marker.markerId.value == 'MeningJoylashuvim');
      if (meningJoylashuvim != null) {
        myMarkers.add(
          Marker(
            markerId: const MarkerId('MeningJoylashuvim'),
            position: meningJoylashuvim!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(
              title: "Bu MEN",
              snippet: "Xush Kelibsiz",
            ),
          ),
        );
      }
    });
  }

  void addMarker() async {
    if (meningJoylashuvim != null) {
      setState(() {
        myMarkers.add(
          Marker(
            markerId: MarkerId(UniqueKey().toString()),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            position: meningJoylashuvim!,
          ),
        );

        myPositions.add(meningJoylashuvim!);
      });

      if (myPositions.length >= 2) {
        final points = await LocationService.getPolylines(
          myPositions[myPositions.length - 2],
          myPositions[myPositions.length - 1],
        );

        setState(() {
          polylines.add(
            Polyline(
              polylineId: PolylineId(UniqueKey().toString()),
              color: Colors.blue,
              width: 5,
              points: points,
            ),
          );
        });
      }
    }
  }

  void onMapTypeChanged(MapType type) {
    setState(() {
      currentMapType = type;
    });
  }

  void _getUserLocation() async {
    myLocation = await location.getLocation();
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        myLocation = currentLocation;
        meningJoylashuvim =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updateMyLocationMarker();
        mapController.animateCamera(
          CameraUpdate.newLatLng(meningJoylashuvim!),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<MapType>(
            onSelected: onMapTypeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MapType.normal,
                child: Text('Normal'),
              ),
              const PopupMenuItem(
                value: MapType.satellite,
                child: Text('Satellite'),
              ),
              const PopupMenuItem(
                value: MapType.terrain,
                child: Text('Terrain'),
              ),
              const PopupMenuItem(
                value: MapType.hybrid,
                child: Text('Hybrid'),
              ),
            ],
            child: const Icon(
              Icons.map,
              color: Colors.teal,
              size: 30,
            ),
          ),
          IconButton(
            onPressed: () {
              mapController.animateCamera(
                CameraUpdate.zoomOut(),
              );
            },
            icon: const Icon(Icons.remove_circle),
          ),
          IconButton(
            onPressed: () {
              mapController.animateCamera(
                CameraUpdate.zoomIn(),
              );
            },
            icon: const Icon(Icons.add_circle),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            buildingsEnabled: true,
            onCameraMove: onCameraMove,
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: najotTalim,
              zoom: 15,
            ),
            mapType: currentMapType,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            markers: {
              Marker(
                markerId: MarkerId("NajotTalim"),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan,
                ),
                position: najotTalim,
                infoWindow: const InfoWindow(
                  title: "Najot Talim",
                  snippet: "Xush Kelibsiz",
                ),
              ),
              Marker(
                markerId: MarkerId("NajotTalimOldidagiMagazin"),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                position: najotTalimOldidagiMagazin,
                infoWindow: const InfoWindow(
                  title: "Najot Talim Oldidagi Magazin",
                  snippet: "Xush Kelibsiz",
                ),
              ),
              if (selectedLocation != null)
                Marker(
                  markerId: MarkerId("SelectedLocation"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  position: selectedLocation!,
                  infoWindow: const InfoWindow(
                    title: "Selected Location",
                    snippet: "This is your selected location",
                  ),
                ),
              ...myMarkers,
            },
            polylines: polylines,
          ),
          Positioned(
            top: 16,
            left: 50,
            right: 50,
            child: GooglePlaceAutoCompleteTextField(
              itemClick: (postalCodeResponse) {},
              textEditingController: TextEditingController(),
              googleAPIKey: "AIzaSyBEjfX9jrWudgRcWl2scld4R7s0LtlaQmQ",
              inputDecoration: InputDecoration(
                hintStyle: const TextStyle(color: Colors.blue),
                hintText: "Search location",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              debounceTime: 800,
              countries: const ["us", "uz", "rus"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) async {
                setState(() {
                  selectedLocation = LatLng(
                    double.parse(prediction.lat!),
                    double.parse(prediction.lng!),
                  );
                  mapController.animateCamera(
                    CameraUpdate.newLatLng(selectedLocation!),
                  );
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: addMarker,
        child: const Icon(Icons.add),
      ),
    );
  }
}
