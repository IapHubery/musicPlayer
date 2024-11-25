import { image } from '@kit.ImageKit';
import { effectKit } from '@kit.ArkGraphics2D';

export default class ColorUtil {
  static async getBackgroundColor(imgSrc: string) {
    const imageSource = image.createImageSource(imgSrc);
    const pixelMap: image.PixelMap = await imageSource.createPixelMap()
    effectKit.createColorPicker(pixelMap, (err, colorPicker) => {
      return ColorUtil.handleColor(colorPicker.getAverageColor())
    })
  }

  static handleColor(color: effectKit.Color) {
    return "#" + color.alpha.toString(16) + color.red.toString(16) + color.green.toString(16) + color.blue.toString(16)
  }
}