import 'dart:convert';

import 'package:county/src/county_util.dart';
import 'package:county/src/file_reader.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class CountyService {
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
  Future<List<LatLng>> getBoundaryForCounty({
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

    // Return polygon or multipolygon coordinates (first ring only)
    if (type == 'Polygon') {
      return _extractPolygon(coordinates[0]); // Only outer ring
    } else if (type == 'MultiPolygon') {
      return _extractPolygon(coordinates[0][0]); // First polygon's outer ring
    } else {
      return [];
    }
  }

  /// PRIVATE

  /// Convert raw coordinates into a list of LatLng
  List<LatLng> _extractPolygon(List coords) {
    return coords.map<LatLng>((p) => LatLng(p[1], p[0])).toList();
  }
}
