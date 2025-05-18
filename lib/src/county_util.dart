import 'county_constant.dart';

class CountyUtil {
  static String? getFipsFromStateCode(String code) {
    return CountyConstant.stateCodeToFips[code.toUpperCase()];
  }

  static bool isValidStateCode(String code) {
    return CountyConstant.stateCodeToFips.containsKey(code.toUpperCase());
  }

  static String? getStateCodeFromName(String name) {
    return CountyConstant.stateNameToCode[name];
  }
}
