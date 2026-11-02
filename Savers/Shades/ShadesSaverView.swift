import ScreenSaver
import ScreensaverCore
import ShadesKit

@objc(ShadesSaverView)
final class ShadesSaverView: SingleSceneSaverView {
    override class var descriptor: SceneDescriptor { ShadesScene.descriptor }
}
