import AppKit
import SwiftUI
import UserNotifications
import CryptoKit
import TokenParkCore

final class RPCReader {
    static func executable() -> String? {
        let fm=FileManager.default
        let explicit=UserDefaults.standard.string(forKey:"codexExecutable")
        var candidates=[explicit,ProcessInfo.processInfo.environment["TOKENPARK_CODEX_PATH"],
            "/Applications/ChatGPT.app/Contents/Resources/codex", "/Applications/Codex.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex", "/usr/local/bin/codex"].compactMap { $0 }
        for dir in (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator:":") { candidates.append(String(dir)+"/codex") }
        // Discover common version-manager installations without shell startup files or embedded user paths.
        let home=fm.homeDirectoryForCurrentUser
        for base in [home.appendingPathComponent(".local/share/fnm/node-versions"),home.appendingPathComponent(".nvm/versions/node")] {
            let versions=(try? fm.contentsOfDirectory(at:base,includingPropertiesForKeys:nil)) ?? []
            for version in versions.sorted(by: { $0.lastPathComponent.compare($1.lastPathComponent,options:.numeric) == .orderedDescending }) {
                candidates.append(version.appendingPathComponent(base.path.contains("fnm") ? "installation/bin/codex" : "bin/codex").path)
            }
        }
        for candidate in candidates where fm.isExecutableFile(atPath:candidate) {
            let resolved=URL(fileURLWithPath:candidate).resolvingSymlinksInPath()
            if resolved.pathExtension == "js" {
                let package=resolved.deletingLastPathComponent().deletingLastPathComponent()
                #if arch(arm64)
                let arch="arm64", triple="aarch64-apple-darwin"
                #else
                let arch="x64", triple="x86_64-apple-darwin"
                #endif
                let native=package.appendingPathComponent("node_modules/@openai/codex-darwin-\(arch)/vendor/\(triple)/bin/codex")
                if fm.isExecutableFile(atPath:native.path) { return native.path }
            }
            return candidate
        }
        return nil
    }
    static func fetch() throws -> LimitResponse {
        guard let path = executable() else { throw problem("Codex was not found. Install and sign in to Codex CLI, or choose its executable in Settings.") }
        let process = Process(), input = Pipe(), output = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["app-server","--listen","stdio://"]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = URL(fileURLWithPath:path).deletingLastPathComponent().path + ":/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        process.environment = env
        process.standardInput = input; process.standardOutput = output; process.standardError = FileHandle.nullDevice
        try process.run()
        let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline:.now()+35, execute:timeout)
        defer {
            timeout.cancel(); try? input.fileHandleForWriting.close()
            if process.isRunning { process.terminate() }
        }
        func send(_ object: [String:Any]) throws {
            var data = try JSONSerialization.data(withJSONObject:object); data.append(10)
            try input.fileHandleForWriting.write(contentsOf:data)
        }
        try send(["id":1,"method":"initialize","params":["clientInfo":["name":"tokenpark","title":AppInfo.name,"version":AppInfo.version]]])
        var pending = Data()
        while true {
            let chunk = output.fileHandleForReading.availableData
            guard !chunk.isEmpty else { throw problem("The read timed out or Codex exited. Check your CLI sign-in and try again.") }
            pending.append(chunk)
            guard pending.count < 2_000_000 else { throw problem("The Codex response was too large. Reading stopped.") }
            while let newline = pending.firstIndex(of:10) {
                let line = Data(pending[..<newline]); pending.removeSubrange(...newline)
                guard let object = (try? JSONSerialization.jsonObject(with:line)) as? [String:Any], let id = object["id"] as? Int else { continue }
                if object["error"] != nil { throw problem("Codex declined the request. Check CLI sign-in, account access and version.") }
                if id == 1 {
                    try send(["method":"initialized","params":[:]])
                    try send(["id":2,"method":"account/rateLimits/read","params":[:]])
                } else if id == 2, let result = object["result"] {
                    let data = try JSONSerialization.data(withJSONObject:result)
                    let decoded = try JSONDecoder().decode(LimitResponse.self, from:data)
                    guard let w = decoded.window, w.usedPercent.isFinite, (0...100).contains(w.usedPercent) else { throw problem("No supported allowance window was returned.") }
                    return decoded
                }
            }
        }
    }
    static func problem(_ text:String)->NSError { NSError(domain:"TokenPark",code:1,userInfo:[NSLocalizedDescriptionKey:text]) }
}

final class QuotaStore: ObservableObject {
    @Published var snapshot: LimitResponse?
    @Published var updated: Date?
    @Published var samples: [Sample] = []
    @Published var refreshing = false
    @Published var error: String?
    @Published var now = Date()
    @Published var planCoupons: Int = UserDefaults.standard.object(forKey:"planCoupons") as? Int ?? 1
    @Published var autoBest = UserDefaults.standard.object(forKey:"autoBest") as? Bool ?? true
    @Published var preferredPace = UserDefaults.standard.double(forKey:"preferredPace")
    @Published var buffer: Double = UserDefaults.standard.object(forKey:"buffer") as? Double ?? 3
    @Published var notifications = UserDefaults.standard.bool(forKey:"notifications")
    @Published var notificationMessage: String?
    @Published var menuBarDisplay = MenuBarDisplay(rawValue: UserDefaults.standard.string(forKey:"menuBarDisplay") ?? "") ?? .progress {
        didSet {
            UserDefaults.standard.set(menuBarDisplay.rawValue,forKey:"menuBarDisplay")
            onChange?()
        }
    }
    var onChange: (() -> Void)?
    private var tick: Timer?
    private var lastAttempt: Date?
    private var thresholdKey: String? = UserDefaults.standard.string(forKey:"lastThresholdNotice")
    private let cacheURL: URL = {
        let root = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask).first!.appendingPathComponent("TokenPark",isDirectory:true)
        try? FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        return root.appendingPathComponent("snapshot.json")
    }()
    init(preview: Bool = false) {
        if preview { return }
        if let data = try? Data(contentsOf:cacheURL), let c = try? JSONDecoder().decode(Cache.self,from:data) {
            snapshot=c.snapshot; updated=c.updated; samples=c.samples
        }
        tick = Timer.scheduledTimer(withTimeInterval:60,repeats:true) { [weak self] _ in
            guard let self else { return }; self.now=Date(); self.onChange?()
            if self.lastAttempt == nil || Date().timeIntervalSince(self.lastAttempt!) >= 1800 { self.refresh() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName:NSWorkspace.didWakeNotification,object:nil,queue:.main) { [weak self] _ in self?.refreshIfNeeded() }
    }
    var remaining: Double? { snapshot?.window.map { max(0,100-$0.usedPercent) } }
    var reset: Date? { snapshot?.window?.resetsAt.map(Date.init(timeIntervalSince1970:)) }
    var days: Double? { reset.map { $0.timeIntervalSince(now)/86400 } }
    var count: Int? { snapshot?.rateLimitResetCredits?.availableCount }
    var credits: [Credit] { (snapshot?.rateLimitResetCredits?.credits ?? []).filter { $0.status == "available" }.sorted { ($0.expiresAt ?? .infinity) < ($1.expiresAt ?? .infinity) } }
    var firstExpiry: Date? { credits.compactMap(\.expiry).filter { $0 > now }.min() }
    var stale: Bool { updated == nil || now.timeIntervalSince(updated!) > 2100 || (reset != nil && reset! <= now) }
    var recommendation: Recommendation {
        guard !stale,error == nil,!expiredUnrefreshed, let remaining,let reset else { return Recommendation(tickets:nil,reason:"Refresh to get a recommendation.",provisional:true) }
        let recent=samples.filter { now.timeIntervalSince($0.date)<86400 }
        let span=recent.last.flatMap { last in recent.first.map { last.date.timeIntervalSince($0.date) } } ?? 0
        let pace=preferredPace>0 ? preferredPace : span>=21600 ? observed : nil
        return Plan.recommend(left:remaining,buffer:buffer,reset:reset,now:now,credits:credits,count:count,pace:pace,windowDays:Double(snapshot?.window?.windowDurationMins ?? 10080)/1440)
    }
    var usablePlan: Int { max(0,min(3,autoBest ? recommendation.tickets ?? 0 : planCoupons,count ?? 0)) }
    func select(_ tickets:Int) { planCoupons=tickets;autoBest=false;settingsChanged() }
    func useBest() { autoBest=true;settingsChanged() }
    var daily: Double? { guard !stale, error == nil, !expiredUnrefreshed, let remaining, let days else { return nil }; return Plan.daily(left:remaining,buffer:buffer,coupons:usablePlan,days:days) }
    func budget(coupons: Int) -> Double? {
        guard !stale, error == nil, !expiredUnrefreshed,
              coupons >= 0, coupons <= (count ?? 0),
              let remaining, let days, days > 0 else { return nil }
        return Plan.daily(left: remaining, buffer: buffer, coupons: coupons, days: 1)
    }
    var forecast: QuotaForecast? {
        guard let total = budget(coupons: usablePlan), let days else { return nil }
        return QuotaForecast(total: total, days: days, pace: observed)
    }
    var observed: Double? { guard !stale,error == nil else { return nil }; return Plan.observed(samples,now:now) }
    var expiredUnrefreshed: Bool { credits.contains { ($0.expiry ?? .distantFuture) <= now } }
    var needsCoupon: Bool { !stale && error == nil && usablePlan>0 && (remaining ?? 100)<=buffer }
    var urgent: Bool { firstExpiry.map { $0.timeIntervalSince(now)<86400 } ?? false }
    var headroom: QuotaHeadroom {
        guard !stale, error == nil, !expiredUnrefreshed else { return .unknown }
        return .evaluate(budget:daily,pace:observed)
    }
    var statusMessage: String {
        if let error { return error }
        if expiredUnrefreshed { return "A ticket expired. Refresh to confirm your inventory." }
        if stale { return "Refresh needed" }
        if needsCoupon { return "Time to use a ticket" }
        if urgent { return "A ticket expires soon" }
        if let d=daily, d == 0 { return "No spendable quota in this plan" }
        if let d=daily,let o=observed,d>0 {
            if o < d*0.9 { return "Room to use more" }
            if o > d*1.1 { return "Consider slowing down" }
            return "You are on pace"
        }
        return "Building your pace history"
    }
    var deadlineWarning: String? {
        guard let expiry=firstExpiry,usablePlan>0,let daily, daily>0,let remaining else { return nil }
        let predicted=now.addingTimeInterval(max(0,remaining-buffer)/daily*86400)
        return predicted >= expiry ? "This ticket may expire before you reach the buffer. Redeem earlier or adjust your plan." : nil
    }
    func refreshIfNeeded() {
        now=Date()
        if updated == nil || now.timeIntervalSince(updated!)>=1800 { refresh() }
    }
    func refresh() {
        guard !refreshing else { return }
        refreshing=true; lastAttempt=Date(); onChange?()
        DispatchQueue.global(qos:.utility).async {
            let result=Result { try RPCReader.fetch() }
            DispatchQueue.main.async {
                self.refreshing=false; self.now=Date()
                switch result {
                case .success(let response):
                    self.snapshot=response; self.updated=self.now; self.error=nil
                    if let window=response.window, let reset=window.resetsAt {
                        let identity=response.accountId ?? "unknown"
                        let key=SHA256.hash(data:Data(identity.utf8)).map { String(format:"%02x",$0) }.joined()
                        self.samples=self.samples.filter { self.now.timeIntervalSince($0.date)<172800 && $0.account==key }
                        self.samples.append(Sample(date:self.now,used:window.usedPercent,reset:reset,count:response.rateLimitResetCredits?.availableCount,account:key))
                    }
                    if let data=try? JSONEncoder().encode(Cache(snapshot:response,updated:self.now,samples:self.samples)),
                       var object=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],var snap=object["snapshot"] as? [String:Any] {
                        snap.removeValue(forKey:"accountId");object["snapshot"]=snap
                        if let clean=try? JSONSerialization.data(withJSONObject:object) { try? clean.write(to:self.cacheURL,options:.atomic) }
                    }
                    self.scheduleNotifications()
                case .failure(let failure): self.error=failure.localizedDescription
                }
                self.onChange?()
            }
        }
    }
    func settingsChanged() {
        UserDefaults.standard.set(autoBest,forKey:"autoBest"); UserDefaults.standard.set(preferredPace,forKey:"preferredPace"); UserDefaults.standard.set(planCoupons,forKey:"planCoupons"); UserDefaults.standard.set(buffer,forKey:"buffer")
        scheduleNotifications(); onChange?()
    }
    func enableNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.sound]) { ok,_ in
            DispatchQueue.main.async {
                self.notifications=ok; UserDefaults.standard.set(ok,forKey:"notifications")
                self.notificationMessage=ok ? "Expiry and buffer reminders are enabled." : "Notifications are not allowed. Enable them in System Settings."
                self.scheduleNotifications()
            }
        }
    }
    func disableNotifications() {
        notifications=false; UserDefaults.standard.set(false,forKey:"notifications")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    func scheduleNotifications() {
        guard notifications else { return }
        let center=UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for credit in credits {
            guard let expiry=credit.expiry,expiry>now else { continue }
            for hours in [24,3] {
                let delay=expiry.timeIntervalSinceNow-Double(hours)*3600
                guard delay>1 else { continue }
                let content=UNMutableNotificationContent(); content.title="A reset ticket expires in \(hours) hours"
                content.body="Expires \(Self.dateText(expiry)). Open NextReset to review your plan."; content.sound = .default
                let request=UNNotificationRequest(identifier:"expiry-\(credit.id)-\(hours)",content:content,trigger:UNTimeIntervalNotificationTrigger(timeInterval:delay,repeats:false))
                center.add(request)
            }
        }
        if needsCoupon,let reset=snapshot?.window?.resetsAt {
            let key="\(reset)-\(count ?? 0)"
            if thresholdKey != key {
                thresholdKey=key; UserDefaults.standard.set(key,forKey:"lastThresholdNotice")
                let content=UNMutableNotificationContent();content.title="You have reached the ticket buffer";content.body="\(Int(remaining ?? 0))% remaining. You can redeem a planned reset ticket.";content.sound = .default
                center.add(UNNotificationRequest(identifier:"buffer-\(key)",content:content,trigger:nil))
            }
        }
    }
    static func dateText(_ date:Date)->String {
        let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.dateFormat="MMM d, HH:mm:ss"; return f.string(from:date)+" · "+TimeZone.current.identifier
    }
    static func countdown(_ date:Date,now:Date)->String {
        let seconds=max(0,date.timeIntervalSince(now));let hours=Int(seconds/3600)
        return seconds<=0 ? "Expired" : hours>=24 ? "\(hours/24)d \(hours%24)h left" : "\(hours)h \(Int(seconds/60)%60)m left"
    }
}
