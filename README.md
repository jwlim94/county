# county

`county` is a Flutter package that provides utilities to retrieve U.S. county and state information, including the ability to extract county boundary data which can be visualized using Google Maps.

## Features

- Get the county name and state code from a user-provided address
- Retrieve boundary coordinates for a given county
- Works for both iOS and Android
- No native setup required

## Getting Started

This package does not require additional platform-specific setup.

To test the package in action, you can use the provided example.

### Run the example

1. Navigate to the `example` directory
2. Create a `.env` file
3. Add the following line (replace with your actual API key):

   ```
   GOOGLE_PLACE_AUTO_COMPLETE_API_KEY=<your_api_key>
   ```

4. Configure your Google Maps API key:

   #### iOS

   In `example/ios/Runner/AppDelegate.swift`, you will see:

   ```swift
   GMSServices.provideAPIKey("<your_api_key>")
   ```

   Replace `<your_api_key>` with your actual key.

   #### Android

   In `example/android/app/src/main/AndroidManifest.xml`, inside the `<application>` tag, you will see:

   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="<your_api_key>"/>
   ```

   Replace `<your_api_key>` with your actual key.

5. Run the example:

   ```bash
   flutter run
   ```

## Usage

```dart
final service = CountyService();

final result = await service.getCountyAndStateCodeFromAddress(
  '1600 Amphitheatre Parkway, Mountain View, CA',
);

if (result.county != null && result.stateCode != null) {
  final boundary = await service.getBoundaryForCounty(
    county: result.county!,
    stateCode: result.stateCode!,
  );

  // Use boundary (List<LatLng>) to draw on Google Maps
}
```

## Additional Information

- County boundaries are based on a static `us_counties.json` file included in the package.
- Contributions welcome via GitHub.
- Please file issues if you encounter problems or want to request features.
