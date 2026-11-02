import ScreenSaver
import ScreensaverCore
import PsykalaKit

@objc(PsykalaSaverView)
final class PsykalaSaverView: SingleSceneSaverView {
    override class var descriptor: SceneDescriptor { PsykalaScene.descriptor }
}
