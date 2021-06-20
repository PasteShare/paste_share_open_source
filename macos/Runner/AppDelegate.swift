import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    var statusBarItem: NSStatusItem! = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.squareLength)
    @IBOutlet weak var menu: NSMenu!
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let statusImage = NSImage.init(named: "AppIcon-grey");
        statusImage?.size = NSMakeSize(20.0, 20.0);
        statusBarItem?.image = statusImage;
        statusBarItem?.action = #selector(self.statusBarButtonClicked)
        statusBarItem?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
//        statusBarItem?.action = #selector(self.statusBarButtonClicked)
//        statusBarItem?.sendAction(on: [.leftMouseUp, .rightMouseUp])

//        statusBarMenu.addItem(
//            withTitle: "Order a burrito",
//            action: #selector(AppDelegate.orderABurrito),
//            keyEquivalent: "")
//
//        statusBarMenu.addItem(
//            withTitle: "Cancel burrito order",
//            action: #selector(AppDelegate.cancelBurritoOrder),
//            keyEquivalent: "")
    }
    @objc func statusBarButtonClicked() {
//        mainFlutterWindow.makeKeyAndOrderFront(nil);
        
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.rightMouseUp {
            let menu = NSMenu.init(title: NSLocalizedString("APP_NAME", tableName: "InfoPlist", value: "", comment: ""));
            menu.delegate = self;
            menu.addItem(withTitle: "Show PasteShare", action: #selector(self.showApp), keyEquivalent: "")
            menu.addItem(withTitle: "Quit", action: #selector(self.exitApp), keyEquivalent: "")
            statusBarItem.menu = menu;
            statusBarItem.button?.performClick(nil);
        } else {
            NSApp.activate(ignoringOtherApps: true);
        }
    }
    @objc func showApp() {
        NSApp.activate(ignoringOtherApps: true);
    }
    @objc func exitApp() {
        NSApplication.shared.terminate(self);
    }
}
extension AppDelegate: NSMenuDelegate {
    // 为了保证按钮的单击事件设置有效，menu要去除
    func menuDidClose(_ menu: NSMenu) {
        statusBarItem.menu = nil;
    }
}
