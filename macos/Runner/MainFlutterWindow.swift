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
    
    // 항상 다른 앱 위에 표시되도록 설정
    self.level = NSWindow.Level.floating

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
