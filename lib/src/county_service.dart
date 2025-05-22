import 'dart:convert';

import 'package:county/src/county_util.dart';
import 'package:county/src/file_reader.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CountyService {
  Map<String, dynamic>? _countyCentroids;

  /// Returns the county name for a given address
  Future<String?> getCountyFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      final location = locations.first;
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) return null;

      return placemarks.first.subAdministrativeArea;
    } catch (e) {
      debugPrint('Error getting county from address: $e');
      return null;
    }
  }

  /// Returns both county name and state code (e.g. 'CA') for a given address
  Future<({String? county, String? stateCode})>
  getCountyAndStateCodeFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return (county: null, stateCode: null);

      final location = locations.first;
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) return (county: null, stateCode: null);

      final placemark = placemarks.first;
      final state = placemark.administrativeArea;
      final code = CountyUtil.getStateCodeFromName(state ?? '') ?? state;
      return (county: placemark.subAdministrativeArea, stateCode: code);
    } catch (e) {
      debugPrint('Error extracting county/state: $e');
      return (county: null, stateCode: null);
    }
  }

  /// Returns the bounday coordinates for a specific county name and state code
  Future<List<latlong.LatLng>> getBoundaryForCounty({
    required String county,
    required String stateCode,
  }) async {
    // Convert state code (e.g. 'CA') to FIPS code (e.g. '06')
    final fipsCode = CountyUtil.getFipsFromStateCode(stateCode.toUpperCase());
    if (fipsCode == null) {
      throw ArgumentError('Unknown state code: $stateCode');
    }

    // Load GeoJSON data from local asset
    String path = 'packages/county/assets/us_counties.json';
    String rawJson = await FileReader.readStringFromFile(path);
    final data = json.decode(rawJson);

    final features = data['features'] as List;

    // Normalize county name (e.g. "Santa Clara County" to "Santa Clara")
    final normalizedCounty =
        county
            .replaceAll(RegExp(r'\s+County$', caseSensitive: false), '')
            .trim();

    // Find feature that matches both county name and state FIPS code
    final feature = features.cast<Map<String, dynamic>>().firstWhere((f) {
      final props = f['properties'];
      return (props['NAME'] as String).toLowerCase() ==
              normalizedCounty.toLowerCase() &&
          props['STATE'] == fipsCode;
    }, orElse: () => {});
    if (feature.isEmpty) return [];

    final geometry = feature['geometry'];
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];

    // Return polygon or multipolygon coordinates
    if (type == 'Polygon') {
      return _extractPolygon(coordinates[0]);
    } else if (type == 'MultiPolygon') {
      final multi = _extractPolygonsFromMultiPolygon(coordinates);
      return multi.expand((polygon) => polygon).toList();
    } else {
      return [];
    }
  }

  /// Returns the centroid (LatLng) of a given county
  Future<LatLng?> getCountyCentroid({
    required String stateCode,
    required String countyName,
  }) async {
    final key = '${stateCode}_$countyName';

    _countyCentroids ??= await _loadCountyCentroids();

    final data = _countyCentroids![key];
    if (data == null) return null;

    return LatLng(data['lat'], data['lng']);
  }

  /// PRIVATE

  /// Converts a single polygon's raw coordinate list to a list of LatLng
  List<latlong.LatLng> _extractPolygon(List coords) {
    return coords
        .map<latlong.LatLng>((p) => latlong.LatLng(p[1], p[0]))
        .toList();
  }

  /// Converts a MultiPolygon's raw coordinates to a list of LatLng lists
  List<List<latlong.LatLng>> _extractPolygonsFromMultiPolygon(
    List multiCoords,
  ) {
    return multiCoords.map<List<latlong.LatLng>>((polygonCoords) {
      return polygonCoords[0]
          .map<latlong.LatLng>((p) => latlong.LatLng(p[1], p[0]))
          .toList();
    }).toList();
  }

  /// Loads county centroid data from a local JSON asset file
  Future<Map<String, dynamic>> _loadCountyCentroids() async {
    String path = 'packages/county/assets/us_counties_centroids.json';
    final rawJson = await FileReader.readStringFromFile(path);
    return json.decode(rawJson) as Map<String, dynamic>;
  }
}
