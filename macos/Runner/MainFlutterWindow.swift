import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 최소 크기 설정
    self.minSize = NSSize(width: 400, height: 600)
    // 최대 크기 설정 (옵션)
    self.maxSize = NSSize(width: 800, height: 1200)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
