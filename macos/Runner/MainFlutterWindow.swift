import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    
    // 현대적인 macOS 창 스타일 적용
    self.styleMask.insert(.fullSizeContentView)
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = true
    self.titleVisibility = .hidden  // 앱 제목 숨기기
    
    // 툴바 설정
    let toolbar = NSToolbar(identifier: NSToolbar.Identifier("MainToolbar"))
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar
    
    // 창 크기 및 위치 설정
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 450, height: 550)
    self.maxSize = NSSize(width: 800, height: CGFloat.greatestFiniteMagnitude)
    
    // 창 모서리 반경 설정
    self.isOpaque = false
    self.backgroundColor = .clear
    
    // 비주얼 이펙트 뷰 설정
    if let contentView = self.contentView {
      let visualEffectView = NSVisualEffectView()
      visualEffectView.state = .active
      visualEffectView.material = .windowBackground
      visualEffectView.blendingMode = .behindWindow
      contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
      visualEffectView.frame = contentView.bounds
      visualEffectView.autoresizingMask = [.width, .height]
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
  
  // 창 모서리 반경 설정을 위한 메서드 오버라이드
  override var canBecomeKey: Bool {
    return true
  }
  
  override var canBecomeMain: Bool {
    return true
  }
}
