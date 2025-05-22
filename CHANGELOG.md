## 0.0.1

- Initial release of the `county` package.
- Provides utilities to retrieve US county and state information.
- Supports parsing GeoJSON data to extract county boundaries.
- Includes a `CountyService` to get county and state code from an address.
- Example app included with Google Maps integration and autocomplete search.

## 0.0.2

- Updated example `pubspect.yaml` to remove duplicated name.

## 0.1.0

- Added `getCountyCentroid()` to retrieve the geographic center (LatLng) of a county.
- Fixed logic for parsing MultiPolygon county boundaries from GeoJSON data.
- Updated README to reflect new functionality
