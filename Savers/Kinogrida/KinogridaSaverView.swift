import ScreenSaver
import ScreensaverCore
import KinogridaKit

@objc(KinogridaSaverView)
final class KinogridaSaverView: SingleSceneSaverView {
    override class var descriptor: SceneDescriptor { KinogridaScene.descriptor }
}
