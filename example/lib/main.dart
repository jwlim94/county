import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:county/county.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CountyLookupPage(),
    );
  }
}

class CountyLookupPage extends StatefulWidget {
  const CountyLookupPage({super.key});

  @override
  State<CountyLookupPage> createState() => _CountyLookupPageState();
}

class _CountyLookupPageState extends State<CountyLookupPage> {
  final controller = TextEditingController();
  String? countyName;
  String? stateCode;
  List<latlong.LatLng> boundary = [];
  GoogleMapController? mapController;

  Future<void> _lookupCountyFromAddress(String address) async {
    final service = CountyService();
    final result = await service.getCountyAndStateCodeFromAddress(address);

    if (result.county == null || result.stateCode == null) {
      setState(() {
        countyName = null;
        stateCode = null;
        boundary = [];
      });
      return;
    }

    final boundaryResult = await service.getBoundaryForCounty(
      county: result.county!,
      stateCode: result.stateCode!,
    );

    setState(() {
      countyName = result.county;
      stateCode = result.stateCode;
      boundary = boundaryResult;
    });

    if (mapController != null && boundary.isNotEmpty) {
      final center = boundary[0];
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(center.latitude, center.longitude),
          10,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('County Lookup')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  height: 50,
                  child: GooglePlaceAutoCompleteTextField(
                    textEditingController: controller,
                    googleAPIKey:
                        dotenv.env['GOOGLE_PLACE_AUTO_COMPLETE_API_KEY'] ?? '',
                    inputDecoration: InputDecoration(
                      hintText: "Search your location",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                    debounceTime: 400,
                    countries: ["us"],
                    isLatLngRequired: true,
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      debugPrint("placeDetails ${prediction.lat}");
                    },
                    itemClick: (Prediction prediction) {
                      controller.text = prediction.description ?? "";
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(
                            offset: prediction.description?.length ?? 0),
                      );

                      if (prediction.description != null) {
                        _lookupCountyFromAddress(prediction.description!);
                      }
                    },
                    seperatedBuilder: Divider(),
                    containerHorizontalPadding: 10,
                    itemBuilder: (context, index, Prediction prediction) {
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(prediction.description ?? ""),
                      );
                    },
                    isCrossBtnShown: true,
                  ),
                ),
                const SizedBox(height: 8),
                if (countyName != null) Text('County: $countyName'),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: const CameraPosition(
                target: LatLng(40.4, -111.9),
                zoom: 8,
              ),
              polygons: boundary.isNotEmpty
                  ? {
                      Polygon(
                        polygonId: const PolygonId('county'),
                        points: boundary
                            .map((p) => LatLng(p.latitude, p.longitude))
                            .toList(),
                        strokeWidth: 2,
                        strokeColor: Colors.blue,
                        fillColor: Colors.blue.withValues(alpha: 0.2),
                      )
                    }
                  : {},
            ),
          )
        ],
      ),
    );
  }
}
