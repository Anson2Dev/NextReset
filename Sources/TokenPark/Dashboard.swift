import AppKit
import SwiftUI
import TokenParkCore

private enum Palette {
    static let green=Color(nsColor:NSColor(name:nil) { $0.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua ? NSColor(red:0.64,green:0.82,blue:0.69,alpha:1) : NSColor(red:0.14,green:0.33,blue:0.23,alpha:1) })
    static let surface=Color(nsColor:NSColor(name:nil) { $0.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua ? NSColor(red:0.11,green:0.15,blue:0.12,alpha:1) : NSColor(red:0.985,green:0.981,blue:0.965,alpha:1) })
    static let sage=Color(nsColor:NSColor(name:nil) { $0.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua ? NSColor(red:0.17,green:0.23,blue:0.18,alpha:1) : NSColor(red:0.92,green:0.94,blue:0.90,alpha:1) })
}

struct Dashboard: View {
    @ObservedObject var store:QuotaStore
    let height:CGFloat
    @State private var page="main"
    @State private var advancedExpanded=false
    private var windowName:String {
        switch store.snapshot?.window?.windowDurationMins {
        case 10080: return "Weekly"
        case 300: return "5-hour"
        default: return "Quota"
        }
    }
    private var pageTitle:String {
        switch page {
        case "settings": return "Settings"
        case "tickets": return "Reset Tickets"
        case "plan": return "Plan Details"
        default: return AppInfo.name
        }
    }
    private var ratio:Double? { guard let d=store.daily,d>0,let o=store.observed else { return nil };return o/d }
    var body:some View {
        VStack(spacing:0) {
            HStack(spacing:9) {
                if page != "main" { Button { page="main" } label: { Image(systemName:"chevron.left").frame(width:28,height:28) }.help("Back").accessibilityLabel("Back") }
                Image(systemName:"circle.lefthalf.filled").foregroundStyle(Palette.green)
                Text(pageTitle).font(.system(size:16,weight:.semibold))
                Spacer()
                if store.refreshing { ProgressView().controlSize(.mini) }
                Button { store.refresh() } label: { Image(systemName:"arrow.clockwise").font(.system(size:15)).frame(width:28,height:28) }.help("Refresh now").accessibilityLabel("Refresh now").disabled(store.refreshing)
                if page == "main" { Button { page="settings" } label: { Image(systemName:"slider.horizontal.3").font(.system(size:15)).frame(width:28,height:28) }.help("Settings").accessibilityLabel("Settings") }
            }.buttonStyle(.plain).padding(.horizontal,20).padding(.top,22).padding(.bottom,14)
            if page == "main" { resetCountdown.padding(.horizontal,20).padding(.bottom,14) }
            ScrollView {
                Group {
                    if page == "main" { mainPanel }
                    else if page == "settings" { settingsPanel }
                    else if page == "plan" { planPanel }
                    else { ticketsPanel }
                }.padding(.horizontal,20).padding(.bottom,12).frame(maxWidth:.infinity,alignment:.leading)
            }.scrollIndicators(.hidden)
            Divider().padding(.horizontal,20)
            HStack {
                Text(store.updated.map { "Updated "+Self.time($0)+" · Every 30 min" } ?? "Every 30 min · Waiting for data").font(.system(size:10)).foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.plain).font(.system(size:11)).foregroundStyle(.secondary)
            }.padding(.horizontal,20).padding(.vertical,12)
        }.frame(width:400,height:height).background(Palette.surface).tint(Palette.green).environment(\.locale,Locale(identifier:"en_US"))
    }
    private var resetCountdown:some View {
        TimelineView(.periodic(from:.now,by:1)) { context in
            VStack(alignment:.leading,spacing:5) {
                HStack(alignment:.firstTextBaseline) {
                    Label("Next Reset",systemImage:"clock").font(.system(size:13,weight:.medium))
                    Spacer()
                    Text(resetText(at:context.date))
                        .font(.system(size:17,weight:.semibold,design:.rounded)).monospacedDigit()
                        .foregroundStyle(Palette.green)
                }
                Text(store.reset.map { windowName+" · "+Self.shortDate($0)+" · "+Self.zone } ?? "Waiting for reset time")
                    .font(.system(size:11)).foregroundStyle(.secondary)
            }.accessibilityElement(children:.combine)
        }
    }
    private func resetText(at date:Date)->String {
        guard let reset=store.reset else { return "—" }
        let seconds=max(0,Int(ceil(reset.timeIntervalSince(date))))
        guard seconds>0 else { return "Awaiting refresh" }
        let days=seconds/86400
        let clock=String(format:"%02d:%02d:%02d",seconds%86400/3600,seconds%3600/60,seconds%60)
        return days>0 ? "\(days)d \(clock)" : clock
    }
    private var mainPanel:some View {
        VStack(alignment:.leading,spacing:13) {
            HStack(alignment:.firstTextBaseline,spacing:7) {
                Text(store.remaining.map { String(format:"%.0f%%",$0) } ?? "—").font(.system(size:36,weight:.semibold,design:.rounded)).monospacedDigit()
                Text(windowName.lowercased()+" remaining").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
            bar(fraction:(store.remaining ?? 0)/100,height:6).accessibilityLabel(windowName+" quota remaining")
                .accessibilityValue(store.remaining.map { String(format:"%.0f percent",$0) } ?? "Unknown")
            budgetCard
            HStack(alignment:.center,spacing:10) {
                Image(systemName:reminderIcon).font(.system(size:19,weight:.medium)).frame(width:34,height:34).background(Palette.sage,in:Circle()).foregroundStyle(Palette.green)
                VStack(alignment:.leading,spacing:3) {
                    Text(store.statusMessage).font(.system(size:13,weight:.semibold)).lineLimit(2)
                    Text(reminderDetail).font(.system(size:11)).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
                }
            }.padding(.vertical,2)
            Divider()
            HStack {
                Text("Reset Tickets").font(.system(size:13,weight:.semibold))
                Spacer()
                Text(store.count.map { "\($0) available" } ?? "Unknown").font(.system(size:12)).foregroundStyle(.secondary)
            }
            Button { page="tickets" } label: {
                HStack {
                    Label("Next expiry",systemImage:"ticket").font(.system(size:12))
                    Spacer()
                    Text(store.firstExpiry.map(Self.shortDate) ?? (store.count == 0 ? "No tickets" : "Unknown")).font(.system(size:12)).monospacedDigit()
                    Image(systemName:"chevron.right").font(.system(size:10)).foregroundStyle(.secondary)
                }.frame(minHeight:28).contentShape(Rectangle())
            }.buttonStyle(.plain).help(store.firstExpiry.map(QuotaStore.dateText) ?? "No expiry time available")
            Text(store.count == nil ? "Refresh to load ticket details." : store.usablePlan > 0 ? "Use near \(Int(store.buffer))% remaining, before expiry." : "No tickets included in this plan.").font(.system(size:11)).foregroundStyle(.secondary)
            if let warning=store.deadlineWarning { Label(warning,systemImage:"exclamationmark.triangle").font(.caption2).foregroundStyle(.orange).fixedSize(horizontal:false,vertical:true) }
        }
    }
    private var budgetCard:some View {
        VStack(alignment:.leading,spacing:10) {
            HStack {
                Text("Daily Budget").font(.system(size:13,weight:.semibold))
                Spacer()
                Text(store.autoBest ? (store.recommendation.provisional ? "Auto · Estimate" : "Auto") : "Manual")
                    .font(.system(size:11)).foregroundStyle(.secondary)
                Button { page="plan" } label: {
                    Image(systemName:"info.circle").frame(width:28,height:28)
                }.buttonStyle(.plain).accessibilityLabel("Plan details").help("How this budget is calculated")
            }
            HStack(spacing:2) {
                ForEach(0...3,id:\.self) { n in
                    let selected=store.usablePlan==n
                    let best=store.recommendation.tickets==n
                    Button { store.select(n) } label: {
                        VStack(spacing:1) {
                            Text(n==0 ? "No ticket" : n==1 ? "1 ticket" : "\(n) tickets").font(.system(size:11,weight:selected ? .semibold : .regular))
                            Text(best ? "Best" : " ").font(.system(size:11,weight:.medium))
                        }.frame(maxWidth:.infinity).frame(height:35)
                            .foregroundStyle(selected ? Color(nsColor:.selectedMenuItemTextColor) : Color.primary)
                            .background(selected ? Color(red:0.14,green:0.33,blue:0.23) : Color.clear,in:RoundedRectangle(cornerRadius:7))
                    }.buttonStyle(.plain).disabled(n>(store.count ?? 0)).opacity(n>(store.count ?? 0) ? 0.35 : 1)
                    .accessibilityLabel("\(n==0 ? "No ticket" : n==1 ? "1 ticket" : "\(n) tickets")\(best ? ", Best recommendation" : "")")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }.padding(2).background(.primary.opacity(0.04),in:RoundedRectangle(cornerRadius:9))
            HStack(alignment:.firstTextBaseline,spacing:6) {
                Text(store.daily.map { String(format:"%.1f%%",$0) } ?? "—").font(.system(size:34,weight:.semibold,design:.rounded)).monospacedDigit()
                Text("/ day").font(.system(size:12)).foregroundStyle(.secondary)
                Spacer(minLength:0)
                if !store.autoBest {
                    Button("Use Best") { store.useBest() }.font(.system(size:11))
                        .disabled(store.recommendation.tickets == nil)
                        .help("Restore automatic plan selection")
                }
            }.help("Percent of one full quota per day, not of your remaining balance. A ticket plan can exceed 100% per day.")
            Divider()
            HStack { Text("Current pace");Spacer();Text(store.observed.map { String(format:"%.1f%% / day",$0) } ?? "Sampling…").monospacedDigit() }.font(.system(size:12))

        }.padding(13).background(Palette.sage,in:RoundedRectangle(cornerRadius:12))
    }
    private var reminderIcon:String {
        if store.error != nil || store.stale { return "exclamationmark" }
        if store.needsCoupon || store.urgent { return "ticket" }
        if let r=ratio { return r<0.9 ? "arrow.up.right" : r>1.1 ? "arrow.down.right" : "checkmark" }
        return "clock"
    }
    private var reminderDetail:String {
        if store.error != nil || store.stale { return "Cached figures are not a live reading." }
        if store.needsCoupon { return "Redeem in Codex, then refresh this panel." }
        if store.urgent { return store.firstExpiry.map { "Expires "+Self.shortDate($0)+" · "+Self.zone } ?? "Check ticket details." }
        if let daily=store.daily,let observed=store.observed,observed>0 { return String(format:"Aim for %.2f× your current pace.",daily/observed) }
        if store.observed == 0 { return "No consumption recorded in the sampled periods." }
        return "Pace appears after 30 minutes of valid samples."
    }
    private var planPanel:some View {
        VStack(alignment:.leading,spacing:18) {
            VStack(alignment:.leading,spacing:6) {
                Text("Daily Budget").font(.headline)
                Text("Percent of a full quota available to use each day until Next Reset, including the tickets selected in your plan. This is a planning estimate.")
            }
            VStack(alignment:.leading,spacing:6) {
                Text("Why Best?").font(.headline)
                Text(store.recommendation.reason)
                if store.recommendation.provisional {
                    Text("Estimated from ticket timing while usage history builds.").foregroundStyle(.secondary)
                }
            }
            VStack(alignment:.leading,spacing:6) {
                Text("Current pace").font(.headline)
                Text("Recent sampled use, expressed as % / day. It is not the amount used today. 1× means this pace matches your daily budget.")
            }
            VStack(alignment:.leading,spacing:6) {
                Text("Plan selection").font(.headline)
                Text("Selecting a ticket count switches to a manual plan. Use Best restores automatic selection. Changing plans never redeems a ticket.")
            }
            Divider()
            Text("Plans assume using a ticket does not change Next Reset. Refresh after redeeming to use the account's updated reset time.")
                .foregroundStyle(.secondary)
        }.font(.system(size:13)).fixedSize(horizontal:false,vertical:true)
    }
    private var settingsPanel:some View {
        VStack(alignment:.leading,spacing:20) {
            VStack(alignment:.leading,spacing:6) {
                Toggle("Auto-select Best",isOn:$store.autoBest)
                    .onChange(of:store.autoBest) { _,_ in store.settingsChanged() }
                Text("Keep the recommended ticket plan selected.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment:.leading,spacing:6) {
                Toggle("Ticket reminders",isOn:Binding(
                    get:{ store.notifications },
                    set:{ enabled in enabled ? store.enableNotifications() : store.disableNotifications() }
                ))
                Text("24h and 3h before expiry, and when you reach your buffer.")
                    .font(.caption).foregroundStyle(.secondary)
                if let message=store.notificationMessage {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            DisclosureGroup("Advanced",isExpanded:$advancedExpanded) {
                VStack(alignment:.leading,spacing:16) {
                    Stepper("Keep a buffer: \(Int(store.buffer))%",value:$store.buffer,in:0...20,step:1)
                        .onChange(of:store.buffer) { _,_ in store.settingsChanged() }
                    VStack(alignment:.leading,spacing:6) {
                        Text("Daily capacity (% / day)")
                        TextField("0 = automatic",value:$store.preferredPace,format:.number)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Daily capacity, percent per day")
                            .onChange(of:store.preferredPace) { _,_ in
                                store.preferredPace=max(0,min(1000,store.preferredPace));store.settingsChanged()
                            }
                        Text("Percent of a full quota. Use 0 to estimate from your history after 6 hours.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Divider()
                    VStack(alignment:.leading,spacing:6) {
                        Text("Codex connection").fontWeight(.medium)
                        Text("Detected automatically. Choose a program only if NextReset cannot find Codex.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Locate Codex…") { chooseExecutable() }
                    }
                    Text("Best is an estimate. Plans assume using a ticket does not change the next reset. Refresh after redeeming.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.top,12)
            }
            Text("Refreshes every 30 minutes. Tickets are never redeemed automatically.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            VStack(alignment:.leading,spacing:10) {
                Text("About").font(.headline)
                Text(AppInfo.name).fontWeight(.semibold)
                Text("v\(AppInfo.version) · MIT License").foregroundStyle(.secondary)
                Text("Author: Anson Ho")
                Link("anson.im",destination:AppInfo.authorWebsite)
                Link("anson@bestapp.us",destination:AppInfo.authorEmail)
                Link("GitHub · Anson2Dev/NextReset",destination:AppInfo.github)
                Link("Official website",destination:AppInfo.website)
            }.textSelection(.enabled)
        }.font(.system(size:13)).toggleStyle(.switch)
    }
    private var ticketsPanel:some View {
        VStack(alignment:.leading,spacing:16) {
            Text("All expiry times · \(Self.zone)").font(.subheadline).foregroundStyle(.secondary)
            ForEach(store.credits) { credit in
                VStack(alignment:.leading,spacing:5) {
                    Label(credit.expiry.map(QuotaStore.dateText) ?? "Expiry unknown",systemImage:"ticket").font(.subheadline).textSelection(.enabled)
                    if let date=credit.expiry { Text(QuotaStore.countdown(date,now:store.now)).font(.caption).foregroundStyle(date.timeIntervalSince(store.now)<86400 ? Color.orange : Color.secondary) }
                }
                Divider()
            }
            if store.credits.isEmpty { Text(store.count == 0 ? "No reset tickets available." : "The service did not return ticket details.").font(.subheadline) }
            Text("Times are converted from the service's absolute expiry timestamps to your system time zone. Redeem before the deadline, not at midnight.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private func bar(fraction:Double,height:CGFloat)->some View {
        GeometryReader { geo in
            ZStack(alignment:.leading) {
                Capsule().fill(.primary.opacity(0.09))
                Capsule().fill(Palette.green.opacity(0.8)).frame(width:geo.size.width*max(0,min(1,fraction)))
            }
        }.frame(height:height).accessibilityLabel("\(Int(fraction*100)) percent")
    }
    static func shortDate(_ date:Date)->String { let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.dateFormat="MMM d, HH:mm";return f.string(from:date) }
    static func time(_ date:Date)->String { let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.dateFormat="HH:mm";return f.string(from:date) }
    static var zone:String { let offset=TimeZone.current.secondsFromGMT();return String(format:"GMT%@%02d:%02d",offset>=0 ? "+" : "−",abs(offset)/3600,abs(offset)%3600/60) }
    private func chooseExecutable() {
        let panel=NSOpenPanel();panel.canChooseDirectories=false;panel.canChooseFiles=true;panel.message="Choose your installed Codex executable"
        if panel.runModal() == .OK,let url=panel.url { UserDefaults.standard.set(url.path,forKey:"codexExecutable");store.refresh() }
    }
}
