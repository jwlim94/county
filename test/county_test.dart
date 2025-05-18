import 'package:flutter_test/flutter_test.dart';
import 'package:county/county.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CountyService', () {
    final service = CountyService();

    test('getCountyFromAddress returns a county name', () async {
      final result = await service.getCountyFromAddress(
        '1600 Amphitheatre Parkway, Mountain View, CA',
      );
      expect(result, isNotNull);
    });

    test(
      'getCountyAndStateFromAddress returns both county and state',
      () async {
        final result = await service.getCountyAndStateCodeFromAddress(
          '1600 Amphitheatre Parkway, Mountain View, CA',
        );
        expect(result.county, isNotNull);
        expect(result.stateCode, isNotNull);
      },
    );

    test('getBoundaryForCounty returns polygon for Utah County', () async {
      final result = await service.getBoundaryForCounty(
        county: 'Santa Clara County',
        stateCode: 'CA',
      );
      expect(result, isNotEmpty);
    });
  });
}
