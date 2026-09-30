import AppKit
import SwiftUI
import UserNotifications
import TokenParkCore

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let store=QuotaStore()
    var status:NSStatusItem!
    let popover=NSPopover()
    func applicationDidFinishLaunching(_ notification:Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate=self
        status=NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        if let button=status.button { button.target=self;button.action=#selector(toggle);button.font=NSFont.monospacedDigitSystemFont(ofSize:12,weight:.medium) }
        popover.behavior = .transient
        popover.contentViewController=NSHostingController(rootView:Dashboard(store:store,height:min(600,(NSScreen.main?.visibleFrame.height ?? 800)-90)))
        store.onChange={ [weak self] in self?.updateStatus() }
        updateStatus();store.refresh()
        DispatchQueue.main.asyncAfter(deadline:.now()+1) { self.toggle() }
    }
    func updateStatus() {
        guard let button=status?.button else { return }
        let left=store.remaining.map { String(format:"%.0f%%",$0) } ?? "—"
        var text=left
        if let count=store.count,count>0 { text += " · \(count) tickets" }
        if let d=store.daily, let o=store.observed,d>0 { text += o < d*0.9 ? " ↑" : o>d*1.1 ? " ↓" : " ≈" }
        button.title=" "+text
        if store.symbol == "circle" {
            button.image=ring(store.remaining ?? 0)
        } else { button.image=NSImage(systemSymbolName:store.symbol,accessibilityDescription:store.statusMessage) }
        button.imagePosition = .imageLeading
        button.toolTip="\(AppInfo.name): \(store.statusMessage)\n"+(store.firstExpiry.map { "First expiry: "+QuotaStore.dateText($0) } ?? "")
        button.setAccessibilityLabel("\(AppInfo.name), \(left) remaining, \(store.count ?? 0) tickets, \(store.statusMessage)")
    }
    func ring(_ value:Double)->NSImage {
        let image=NSImage(size:NSSize(width:17,height:17),flipped:false) { rect in
            NSColor.labelColor.withAlphaComponent(0.25).setStroke()
            let circle=NSBezierPath(ovalIn:NSRect(x:2,y:2,width:13,height:13));circle.lineWidth=2;circle.stroke()
            NSColor.labelColor.setStroke()
            let arc=NSBezierPath();arc.lineWidth=2;arc.lineCapStyle = .round
            arc.appendArc(withCenter:NSPoint(x:8.5,y:8.5),radius:6.5,startAngle:90,endAngle:90-360*max(0,min(100,value))/100,clockwise:true)
            if value>0 { arc.stroke() };return true
        }
        image.isTemplate=true;image.accessibilityDescription="Remaining quota ring";return image
    }
    @objc func toggle() {
        guard let button=status.button else { return }
        if popover.isShown { popover.performClose(nil) }
        else {
            let available=status.button?.window?.screen?.visibleFrame.height ?? NSScreen.main?.visibleFrame.height ?? 800
            popover.contentViewController=NSHostingController(rootView:Dashboard(store:store,height:max(300,min(600,available-90))))
            store.refreshIfNeeded();NSApp.activate(ignoringOtherApps:true);popover.show(relativeTo:button.bounds,of:button,preferredEdge:.minY) }
    }
    func userNotificationCenter(_ center:UNUserNotificationCenter,willPresent notification:UNNotification,withCompletionHandler completionHandler:@escaping(UNNotificationPresentationOptions)->Void) { completionHandler([.banner,.sound]) }
}

if CommandLine.arguments.contains("--probe") {
    do { let result=try RPCReader.fetch();print("Live read OK: remaining \(100-(result.window?.usedPercent ?? 100))%, tickets \(result.rateLimitResetCredits?.availableCount ?? 0)") }
    catch { fputs("\(error.localizedDescription)\n",stderr);exit(1) }
} else {
    signal(SIGPIPE,SIG_IGN)
    let app=NSApplication.shared
    let delegate=AppDelegate();app.delegate=delegate;withExtendedLifetime(delegate) { app.run() }
}
