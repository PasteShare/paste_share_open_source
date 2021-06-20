import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
//    self.styleMask = NSWindow.StyleMask.;
//    self.titlebarAppearsTransparent = true
//    self.backgroundColor = NSColor.init(red: 0.31, green: 0.66, blue: 0.3, alpha: 1)
//    self.backgroundColor = NSColor(red: 81, green: 170, blue: 77, alpha: 1)//    NSColor.
//    UINavigationBarAppearance();
//    self.appearance?.bac; //  = NSColor(red: 81, green: 170, blue: 77, alpha: 0);
//    self.title = NSLocalizedString("APP_NAME", tableName: "InfoPlist", value: "", comment: "");

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
    
    override func close() {
        NSApp.hide(nil);
    }
//    override func keyUp(with event: NSEvent) {
//        print(event.characters);
//    }
}
