import { map, mapCommon } from '@kit.MapKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// Plain holder for a city's name and its WGS84 coordinate.
export class CityCoordinate {
  name: string = '';
  lat: number = 0;
  lng: number = 0;
}

// Plain holder for one conversion: the WGS84 input, the GCJ02 output, and the
// offset distance between them in meters.
export class ConversionResult {
  name: string = '';
  wgs84: mapCommon.LatLng = { latitude: 0, longitude: 0 };
  gcj02: mapCommon.LatLng = { latitude: 0, longitude: 0 };
  offset: number = 0;
}

// Outcome of a rectifyCoordinate call. rectifyCoordinate only returns a changed
// coordinate when the device has an active routing location; otherwise it
// returns the input unchanged. This holder records what actually came back so
// the difference from convertCoordinate is visible.
export class RectifyResult {
  ok: boolean = false;
  lat: number = 0;
  lng: number = 0;
  message: string = '';
}

// Converts a city's WGS84 coordinate to GCJ02 synchronously and measures the
// offset. The synchronous variant returns immediately, suiting per-card display.
export function convertCity(city: CityCoordinate): ConversionResult {
  let result: ConversionResult = new ConversionResult();
  let wgs84: mapCommon.LatLng = { latitude: city.lat, longitude: city.lng };
  let gcj02: mapCommon.LatLng = map.convertCoordinateSync(
    mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, wgs84);

  result.name = city.name;
  result.wgs84 = wgs84;
  result.gcj02 = gcj02;
  result.offset = map.calculateDistance(wgs84, gcj02);
  return result;
}

// Promise-based variant using convertCoordinate. Same result as convertCity
// appropriate for one-off conversions where awaiting is fine.
export async function convertCityAsync(city: CityCoordinate): Promise<ConversionResult> {
  let result: ConversionResult = new ConversionResult();
  let wgs84: mapCommon.LatLng = { latitude: city.lat, longitude: city.lng };
  let gcj02: mapCommon.LatLng = await map.convertCoordinate(
    mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, wgs84);

  result.name = city.name;
  result.wgs84 = wgs84;
  result.gcj02 = gcj02;
  result.offset = map.calculateDistance(wgs84, gcj02);
  return result;
}

// Calls rectifyCoordinate for a city's WGS84 coordinate. Unlike convertCoordinate,
// rectifyCoordinate only adjusts a coordinate when the device has an active
// routing location; without one it returns the input unchanged. This function
// reports whatever the device actually returns.
export async function rectifyCity(context: common.Context, city: CityCoordinate): Promise<RectifyResult> {
  let result: RectifyResult = new RectifyResult();
  try {
    let locations: Array<mapCommon.CoordinateLatLng> = [
      {
        coordinateType: mapCommon.CoordinateType.WGS84,
        location: { latitude: city.lat, longitude: city.lng }
      }
    ];
    let arr: Array<mapCommon.CoordinateLatLng> = await map.rectifyCoordinate(context, locations);
    if (arr.length > 0) {
      result.ok = true;
      result.lat = arr[0].location.latitude;
      result.lng = arr[0].location.longitude;
      result.message = 'returned';
    } else {
      result.message = 'empty result';
    }
  } catch (err) {
    result.ok = false;
    let e: BusinessError = err as BusinessError;
    result.message = `error ${e.code}`;
  }
  return result;
}