import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/core/helpers/lcation_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

Completer<GoogleMapController> _controller = Completer();
Position? position;
double? time=0.0;
double? distance=0.0;
List<LatLng> routePoints = [];
Set<Marker> markers = {};
bool? visible = false;
String? streetName;
final String orsApiKey =
    '5b3ce3597851110001cf62482c8f25e2d8e14f348f0b26bbce04837b';
var progressIndicator = false;
CameraPosition mycameraPosition = CameraPosition(
    target: LatLng(position!.latitude, position!.longitude),
    bearing: 0.0,
    tilt: 0.0,
    zoom: 17);

class _MapScreenState extends State<MapScreen> {
  Future<void> getCurrentPosition() async {
    await LocationHelper.getCurrentPosition();
    position = await Geolocator.getLastKnownPosition().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> _getRoute(LatLng destination) async {
    if (position == null) return;
    setState(() {
      visible = false;
    });

    final start = LatLng(position!.latitude, position!.longitude);
    final response = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${destination.longitude},${destination.latitude}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coords =
          data['features'][0]['geometry']['coordinates'];
      setState(() {
        print('${data}========================');
        print(
            '${data['features'][0]['properties']['segments'][0]['steps'][0]['name']}========================');
        streetName = data['features'][0]['properties']['segments'][0]['steps']
            [0]['name'];
        distance = data['features'][0]['properties']['segments'][0]['distance'];
        time = data['features'][0]['properties']['segments'][0]['duration'];
        routePoints =
            coords.map((coord) => LatLng(coord[1], coord[0])).toList();
      });
      setState(() {
        markers.add(Marker(
          position: destination,
          markerId: MarkerId('2'),
          infoWindow: InfoWindow(title: streetName),
          onTap: () {
            setState(() {
              visible = true;
            });
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });
    } else {
      // Handle errors
      print('Failed to fetch route');
    }
  }

  Future<void> goToCurrentPosition() async {
    GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(mycameraPosition));
  }

  @override
  void initState() {
    super.initState();
    getCurrentPosition();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          position != null
              ? GoogleMap(
                  markers: markers,
                  onTap: (e) {
                    _getRoute(e);
                  },
                  polylines: routePoints != null
                      ? {
                          Polyline(
                            polylineId: const PolylineId('my_polyline'),
                            color: Colors.blue,
                            width: 4,
                            points: routePoints,
                          ),
                        }
                      : {},
                  initialCameraPosition: mycameraPosition,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) =>
                      _controller.complete(controller),
                )
              : Container(
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                ),
          Visibility(
            visible: visible!,
            child: Positioned(
              top: 50,
              left: 50,
              right: 50,
              child: Row(children: [
                Container(
                    padding: EdgeInsets.all(3),
                    height: 50,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.amber[200],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.car_repair_outlined,
                          color: Colors.black,
                          size: 30,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${distance!.toInt()} km',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    )),
                SizedBox(
                  width: 20,
                ),
                Container(
                    padding: EdgeInsets.all(3),
                    height: 50,
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.amber[200],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.watch_later,
                          color: Colors.black,
                          size: 30,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${time!.toInt()} m',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    )),
              ]),
            ),
          )
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 8, 30),
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () {
            goToCurrentPosition();
          },
          child: const Icon(
            Icons.place,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
