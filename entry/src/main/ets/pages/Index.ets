import { CityCoordinate, ConversionResult, RectifyResult,
  convertCity, rectifyCity } from '../conversion/CoordinateConverter';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State supported: boolean = false;
  private cities: CityCoordinate[] = [];
  @State private index: number = 0;

  @State cityName: string = '';
  @State wgs84Text: string = '';
  @State gcj02Text: string = '';
  @State offsetText: string = '';
  @State rectifyText: string = '';

  aboutToAppear(): void {
    // The conversion APIs require the Map.Core capability. The wearable emulator
    // image may not include it, so a physical device is recommended.
    this.supported = canIUse('SystemCapability.Map.Core');
    if (!this.supported) {
      return;
    }

    // Read the fixed city list from resources (stored as a JSON string).
    try {
      let rm = this.getUIContext().getHostContext()!.resourceManager;
      let raw: string = rm.getStringByNameSync('cities_data');
      this.cities = JSON.parse(raw) as CityCoordinate[];
    } catch (err) {
      console.error(`readCities failed: ${err instanceof Error ? err.message : String(err)}`);
      return;
    }

    this.showCity(0);
  }

  // Convert the city at the given index (sync) and update the display fields,
  // then run the rectify call asynchronously and show whatever it returns.
  private showCity(i: number): void {
    if (this.cities.length === 0) {
      return;
    }
    let city: CityCoordinate = this.cities[i];

    let result: ConversionResult = convertCity(city);
    this.cityName = result.name;
    this.wgs84Text = `${result.wgs84.latitude.toFixed(6)}, ${result.wgs84.longitude.toFixed(6)}`;
    this.gcj02Text = `${result.gcj02.latitude.toFixed(6)}, ${result.gcj02.longitude.toFixed(6)}`;
    this.offsetText = `${result.offset.toFixed(1)} m`;

    // rectifyCoordinate is async; show its actual result when it returns.
    this.rectifyText = '...';
    let ctx: common.Context = this.getUIContext().getHostContext() as common.Context;
    rectifyCity(ctx, city).then((r: RectifyResult) => {
      if (r.ok) {
        this.rectifyText = `${r.lat.toFixed(6)}, ${r.lng.toFixed(6)}`;
      } else {
        this.rectifyText = r.message;
      }
    });
  }

  private nextCity(): void {
    this.index = (this.index + 1) % this.cities.length;
    this.showCity(this.index);
  }

  build() {
    Column() {
      if (!this.supported) {
        Text($r('app.string.label_unsupported'))
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
      } else {
        Text(this.cityName)
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 8 })

        Text($r('app.string.label_wgs84'))
          .fontSize(10)
          .fontColor($r('app.color.text_label'))
        Text(this.wgs84Text)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 6 })

        Text($r('app.string.label_gcj02'))
          .fontSize(10)
          .fontColor($r('app.color.text_label'))
        Text(this.gcj02Text)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 6 })

        Text($r('app.string.label_offset'))
          .fontSize(10)
          .fontColor($r('app.color.text_label'))
        Text(this.offsetText)
          .fontSize(14)
          .fontColor($r('app.color.text_offset'))
          .margin({ bottom: 6 })

        Text($r('app.string.label_rectify'))
          .fontSize(10)
          .fontColor($r('app.color.text_label'))
        Text(this.rectifyText)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 10 })

        Row() {
          Text(`${this.index + 1} / ${this.cities.length}  ·  `)
            .fontSize(10)
            .fontColor($r('app.color.text_hint'))
          Text($r('app.string.label_hint'))
            .fontSize(10)
            .fontColor($r('app.color.text_hint'))
        }
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor($r('app.color.screen_background'))
    .onClick(() => {
      if (this.supported) {
        this.nextCity();
      }
    })
  }
}