# county

`county` is a Flutter package that helps you retrieve U.S. county and state information, including boundaries and geographic centroids for map visualization.

## Features

- Get the county name and state code from a user-provided address
- Retrieve boundary coordinates for a given county
- Get the geographic center (centroid) of any county
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

  final centroid = await service.getCountyCentroid(
    stateCode: result.stateCode!,
    countyName: result.county!,
  );

  // Use boundary (List<LatLng>) and centroid (LatLng) to draw on Google Maps
}
```

## Additional Information

- County boundaries are based on a static `us_counties.json` file included in the package.
- County centroids are retrieved from the `us_counties_centroids.json` file.
- Contributions welcome via GitHub.
- Please file issues if you encounter problems or want to request features.
