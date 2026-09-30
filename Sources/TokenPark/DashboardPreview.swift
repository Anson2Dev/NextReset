#if DEBUG
import AppKit
import SwiftUI
import TokenParkCore

/// Synthetic-only visual regression fixtures; never loads account data or saves settings.
@MainActor
func renderDashboardPreviews(to directory:String) throws {
    let output=URL(fileURLWithPath:directory,isDirectory:true)
    try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
    let app=NSApplication.shared
    app.setActivationPolicy(.prohibited)
    let cases:[(String,Double?,Double,Double,Int,Bool)] = [
        ("normal",32,37,3,1,false), ("fast",90,37,3,1,false),
        ("balanced",134/3,37,3,1,false), ("near-balanced",44,37,3,1,false),
        ("very-fast",300,37,3,1,false),
        ("idle",0,37,3,1,false), ("sampling",nil,37,3,1,false),
        ("empty",32,0,3,0,false), ("large",32,37,3,3,false),
        ("short-window",32,37,0.08,1,false), ("dark",32,37,3,1,true),
        ("stale",32,37,3,1,false), ("small-screen",32,37,3,1,false)
    ]
    for (name,pace,left,days,tickets,dark) in cases {
        let store=QuotaStore(preview:true)
        let now=Date();let reset=now.addingTimeInterval(days*86400)
        let json="""
        {"rateLimits":{"primary":{"usedPercent":\(100-left),"windowDurationMins":10080,"resetsAt":\(reset.timeIntervalSince1970)}},"rateLimitResetCredits":{"availableCount":3,"credits":[{"id":"preview1","status":"available","expiresAt":\(now.addingTimeInterval(2*86400).timeIntervalSince1970)},{"id":"preview2","status":"available","expiresAt":\(now.addingTimeInterval(10*86400).timeIntervalSince1970)},{"id":"preview3","status":"available","expiresAt":\(now.addingTimeInterval(20*86400).timeIntervalSince1970)}]}}
        """
        store.snapshot=try JSONDecoder().decode(LimitResponse.self,from:Data(json.utf8))
        store.now=now;store.updated=name == "stale" ? now.addingTimeInterval(-4000) : now
        store.autoBest=name == "normal";store.planCoupons=tickets;store.buffer=3;store.preferredPace=32
        if let pace {
            store.samples=[
                Sample(date:now.addingTimeInterval(-1800),used:100-left-pace/48,reset:reset.timeIntervalSince1970,count:3,account:"synthetic"),
                Sample(date:now,used:100-left,reset:reset.timeIntervalSince1970,count:3,account:"synthetic")
            ]
        }
        let height:CGFloat=name == "small-screen" ? 450 : 680
        let appearance=NSAppearance(named:dark ? .darkAqua : .aqua)!
        app.appearance=appearance
        let host=NSHostingView(rootView:Dashboard(store:store,height:height).environment(\.colorScheme,dark ? .dark : .light))
        host.frame=NSRect(x:0,y:0,width:440,height:height)
        let window=NSWindow(contentRect:host.frame,styleMask:.borderless,backing:.buffered,defer:false)
        window.appearance=appearance;window.contentView=host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until:Date().addingTimeInterval(0.1))
        guard let bitmap=host.bitmapImageRepForCachingDisplay(in:host.bounds) else { continue }
        host.cacheDisplay(in:host.bounds,to:bitmap)
        if let data=bitmap.representation(using:.png,properties:[:]) {
            try data.write(to:output.appendingPathComponent(name+".png"))
        }
        window.contentView=nil
    }
    print("Rendered synthetic previews to \(output.path)")
}
#endif
