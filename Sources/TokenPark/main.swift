import AppKit
import SwiftUI
import UserNotifications
import TokenParkCore

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let store=QuotaStore()
    var status:NSStatusItem!
    let popover=NSPopover()
    private var appearanceObservation:NSKeyValueObservation?
    func applicationDidFinishLaunching(_ notification:Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate=self
        status=NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        if let button=status.button { button.target=self;button.action=#selector(toggle);button.font=NSFont.monospacedDigitSystemFont(ofSize:12,weight:.medium) }
        popover.behavior = .transient
        popover.contentViewController=NSHostingController(rootView:Dashboard(store:store,height:min(600,(NSScreen.main?.visibleFrame.height ?? 800)-90)))
        store.onChange={ [weak self] in self?.updateStatus() }
        appearanceObservation=status.button?.observe(\.effectiveAppearance,options:[.new]) { [weak self] _,_ in
            self?.updateStatus()
        }
        updateStatus();store.refresh()
        DispatchQueue.main.asyncAfter(deadline:.now()+1) { self.toggle() }
    }
    func updateStatus() {
        guard let button=status?.button else { return }
        let left=store.remaining.map { String(format:"%.0f%%",$0) } ?? "—"
        let title=NSMutableAttributedString(string:store.menuBarDisplay == .progress ? "" : " " + left)
        if store.menuBarDisplay == .tickets {
            title.append(NSAttributedString(string:"  "))
            if let icon=NSImage(systemSymbolName:store.needsCoupon ? "ticket.fill" : "ticket",accessibilityDescription:"Bank tickets") {
                let attachment=NSTextAttachment()
                attachment.image=icon
                attachment.bounds=NSRect(x:0,y:-2,width:15,height:12)
                title.append(NSAttributedString(attachment:attachment))
            }
            title.append(NSAttributedString(string:" " + (store.count.map(String.init) ?? "—")))
        }
        title.addAttributes([.font:NSFont.monospacedDigitSystemFont(ofSize:12,weight:.medium),.foregroundColor:NSColor.labelColor],range:NSRange(location:0,length:title.length))
        button.attributedTitle=title
        button.effectiveAppearance.performAsCurrentDrawingAppearance {
            button.image=ring(store.remaining ?? 0)
        }
        button.imagePosition = store.menuBarDisplay == .progress ? .imageOnly : .imageLeading
        button.toolTip="\(AppInfo.name)\n\(left) remaining · \(store.count.map(String.init) ?? "—") bank tickets\n\(store.headroom.label)\n\(store.statusMessage)\n"+(store.firstExpiry.map { "First expiry: "+QuotaStore.dateText($0) } ?? "")
        button.setAccessibilityLabel("\(AppInfo.name), \(left) remaining, \(store.count.map(String.init) ?? "unknown") bank tickets, \(store.headroom.label), \(store.statusMessage)")
    }
    func ring(_ value:Double)->NSImage {
        let warning=store.error != nil || store.stale || store.expiredUnrefreshed
        let headroom=store.headroom
        let image=NSImage(size:NSSize(width:17,height:17),flipped:false) { rect in
            NSColor.labelColor.withAlphaComponent(0.25).setStroke()
            let circle=NSBezierPath(ovalIn:NSRect(x:2,y:2,width:13,height:13));circle.lineWidth=2;circle.stroke()
            NSColor.labelColor.setStroke()
            let arc=NSBezierPath();arc.lineWidth=2;arc.lineCapStyle = .round
            arc.appendArc(withCenter:NSPoint(x:8.5,y:8.5),radius:6.5,startAngle:90,endAngle:90-360*max(0,min(100,value))/100,clockwise:true)
            if value>0 { arc.stroke() }
            if warning {
                let mark=NSAttributedString(string:"!",attributes:[.font:NSFont.systemFont(ofSize:10,weight:.bold),.foregroundColor:NSColor.labelColor])
                let size=mark.size()
                mark.draw(at:NSPoint(x:(17-size.width)/2,y:(17-size.height)/2))
            } else {
                let color:NSColor
                switch headroom {
                case .comfortable: color=NSColor(srgbRed:0.153,green:0.518,blue:0.329,alpha:1)
                case .balanced: color=NSColor(srgbRed:0.839,green:0.608,blue:0.137,alpha:1)
                case .tight: color=NSColor(srgbRed:0.847,green:0.345,blue:0.290,alpha:1)
                case .unknown: color = .secondaryLabelColor
                }
                color.setFill()
                NSBezierPath(ovalIn:NSRect(x:6.5,y:6.5,width:4,height:4)).fill()
            }
            return true
        }
        image.isTemplate=false;image.accessibilityDescription="Remaining quota ring, " + headroom.label;return image
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
