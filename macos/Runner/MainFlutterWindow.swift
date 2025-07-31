import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 최소 크기 설정
    self.minSize = NSSize(width: 400, height: 550)
    // 최대 크기 설정 - 가로만 제한
    self.maxSize = NSSize(width: 800, height: CGFloat.greatestFiniteMagnitude)
    
    // 일반 창 레벨로 설정 (Mission Control에서 정상 동작)
    self.level = NSWindow.Level.normal
    
    // Mission Control에서 정상적으로 표시되도록 설정
    self.collectionBehavior = [.managed, .fullScreenAuxiliary]

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
