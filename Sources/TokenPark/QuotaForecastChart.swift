import SwiftUI
import TokenParkCore

/// One coordinate system owns the plot, labels and symbols. Icons never take part in
/// stack layout, and the plot insets reserve room for their complete drawing bounds.
struct QuotaForecastChart: View {
    let forecast: QuotaForecast?
    let reset: Date?
    var unavailable = false

    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            HStack(spacing:10) {
                Text("Remaining quota").font(.system(size:12,weight:.semibold))
                Spacer(minLength:4)
                legend("Your pace",color:Palette.green,dashed:false)
                legend("Ideal pace",color:.secondary,dashed:true)
            }
            if let forecast {
                plot(forecast)

            } else {
                VStack(spacing:7) {
                    Image(systemName:unavailable ? "arrow.clockwise" : "chart.xyaxis.line")
                    Text(unavailable ? "Refresh to update the forecast" : "Waiting for quota and reset time")
                }.font(.system(size:12)).foregroundStyle(.secondary)
                    .frame(maxWidth:.infinity).frame(height:180)
                    .background(.primary.opacity(0.025),in:RoundedRectangle(cornerRadius:8))
            }
        }.padding(.top,8)
    }

    private func legend(_ title:String,color:Color,dashed:Bool)->some View {
        HStack(spacing:4) {
            Path { p in p.move(to:.init(x:0,y:4));p.addLine(to:.init(x:20,y:4)) }
                .stroke(color,style:StrokeStyle(lineWidth:1.5,dash:dashed ? [4,3] : []))
                .frame(width:20,height:8)
            Text(title).font(.system(size:10)).foregroundStyle(.secondary)
        }.fixedSize()
    }

    private func plot(_ forecast:QuotaForecast)->some View {
        Canvas { context,size in
            let plot=CGRect(x:38,y:27,width:max(1,size.width-58),height:max(1,size.height-56))
            let scale=max(1,forecast.total)
            func point(_ fraction:Double,_ remaining:Double)->CGPoint {
                CGPoint(x:plot.minX+plot.width*min(1,max(0,fraction)),
                        y:plot.minY+plot.height*min(1,max(0,remaining/scale)))
            }
            func line(_ a:CGPoint,_ b:CGPoint,color:Color,width:CGFloat=1,dash:[CGFloat]=[]) {
                var path=Path();path.move(to:a);path.addLine(to:b)
                context.stroke(path,with:.color(color),style:StrokeStyle(lineWidth:width,lineCap:.round,dash:dash))
            }
            func text(_ value:String,at position:CGPoint,color:Color = .secondary,anchor:UnitPoint = .center,weight:Font.Weight = .regular) {
                context.draw(Text(value).font(.system(size:10,weight:weight)).foregroundColor(color),at:position,anchor:anchor)
            }
            for step in 0...4 {
                let y=plot.minY+plot.height*CGFloat(step)/4
                line(.init(x:plot.minX,y:y),.init(x:plot.maxX,y:y),color:.primary.opacity(0.075))
            }
            for step in 0...3 {
                let x=plot.minX+plot.width*CGFloat(step)/3
                line(.init(x:x,y:plot.minY),.init(x:x,y:plot.maxY),color:.primary.opacity(0.075))
                let label:String
                if step == 0 { label="Now" }
                else if step == 3 {
                    let formatter=DateFormatter();formatter.locale=Locale(identifier:"en_US_POSIX")
                    formatter.dateFormat=forecast.days<1 ? "HH:mm" : "MMM d"
                    label=reset.map(formatter.string(from:)) ?? "Reset"
                } else {
                    let hours=forecast.days*24*Double(step)/3
                    let roundedHours=(hours*60).rounded()/60
                    label=roundedHours>=24 ? String(format:"+%.1fd",roundedHours/24).replacingOccurrences(of:".0d",with:"d") : roundedHours>=1 ? String(format:"+%.0fh",roundedHours) : String(format:"+%.0fm",roundedHours*60)
                }
                text(label,at:.init(x:x,y:plot.maxY+16))
            }
            line(.init(x:plot.minX,y:plot.minY),.init(x:plot.minX,y:plot.maxY),color:.secondary.opacity(0.5))
            line(.init(x:plot.minX,y:plot.maxY),.init(x:plot.maxX,y:plot.maxY),color:.secondary.opacity(0.5))
            // Remaining quota decreases upward: the ideal finish is zero at Reset.
            text("0%",at:.init(x:plot.minX-7,y:plot.minY),anchor:.trailing)
            text(String(format:"%.0f%%",scale),at:.init(x:plot.minX-7,y:plot.maxY),anchor:.trailing)
            // The finish pole stays on the exact reset x-coordinate; its flag has a reserved gutter.
            line(.init(x:plot.maxX,y:plot.minY),.init(x:plot.maxX,y:plot.maxY),color:.secondary.opacity(0.7),dash:[2,3])
            text("Reset",at:.init(x:plot.maxX-7,y:plot.minY-16),anchor:.trailing)
            if let flag=context.resolveSymbol(id:"flag") {
                context.draw(flag,in:CGRect(x:plot.maxX-1,y:plot.minY-24,width:18,height:18))
            }
            let start=point(0,forecast.total)
            line(start,point(1,0),color:.secondary.opacity(0.7),width:1.5,dash:[5,5])
            if let fraction=forecast.endFraction,let remaining=forecast.remainingAtReset {
                let end=point(fraction,remaining)
                line(start,end,color:Palette.green,width:2)
                for p in [start,end] {
                    let dot=CGRect(x:p.x-4,y:p.y-4,width:8,height:8)
                    context.fill(Path(ellipseIn:dot.insetBy(dx:-1,dy:-1)),with:.color(Palette.surface))
                    context.fill(Path(ellipseIn:dot),with:.color(Palette.green))
                }
                func lineY(at x:CGFloat)->CGFloat {
                    guard end.x > start.x else { return end.y }
                    let t=min(1,max(0,(x-start.x)/(end.x-start.x)))
                    return start.y+(end.y-start.y)*t
                }
                func crosses(_ rect:CGRect,_ a:CGPoint,_ b:CGPoint)->Bool {
                    let left=max(rect.minX,min(a.x,b.x)),right=min(rect.maxX,max(a.x,b.x))
                    guard left <= right else { return false }
                    guard b.x != a.x else { return rect.minY <= max(a.y,b.y) && rect.maxY >= min(a.y,b.y) }
                    let y1=a.y+(b.y-a.y)*(left-a.x)/(b.x-a.x)
                    let y2=a.y+(b.y-a.y)*(right-a.x)/(b.x-a.x)
                    return max(y1,y2)>=rect.minY && min(y1,y2)<=rect.maxY
                }
                // Put the runner next to the endpoint, never over either line or an axis label.
                let runnerX:CGFloat
                if forecast.runsOutEarly && end.x+29 < plot.maxX { runnerX=end.x+8 }
                else { runnerX=max(plot.minX+3,end.x-25) }
                let lowY=max(lineY(at:runnerX),lineY(at:runnerX+18))
                let highY=min(lineY(at:runnerX),lineY(at:runnerX+18))
                let runnerY=lowY+6+18 <= plot.maxY-3 ? lowY+6 : max(plot.minY+3,highY-24)
                let label=forecast.total == 0 ? "No spendable quota" : forecast.runsOutEarly ? "Used up early" : String(format:"%.0f%% left",remaining)
                let resolved=context.resolve(Text(label).font(.system(size:11,weight:.semibold)).foregroundColor(Palette.green))
                let measured=resolved.measure(in:size)
                var runnerCandidates=[CGRect(x:runnerX,y:runnerY,width:18,height:18)]
                for x in [end.x-25,end.x+8] {
                    for y in [end.y+7,end.y-25,end.y+28,end.y-46] {
                        runnerCandidates.append(CGRect(x:min(plot.maxX-21,max(plot.minX+3,x)),
                                                       y:min(plot.maxY-21,max(plot.minY+3,y)),width:18,height:18))
                    }
                }
                let runnerRect=runnerCandidates.first {
                    !crosses($0.insetBy(dx:-2,dy:-2),start,end) && !crosses($0.insetBy(dx:-2,dy:-2),start,point(1,0))
                } ?? runnerCandidates[0]
                // Find a nearby clear rectangle, checking BOTH curves as well as the runner.
                var candidates:[CGRect]=[]
                for x in [end.x-measured.width-6,end.x+30,end.x-measured.width/2,plot.minX+6] {
                    for y in [end.y-measured.height-12,end.y+28,end.y-measured.height-36,end.y+52,plot.minY+32,plot.maxY-measured.height-30] {
                        candidates.append(CGRect(x:min(plot.maxX-measured.width-4,max(plot.minX+4,x)),
                                                 y:min(plot.maxY-measured.height-4,max(plot.minY+4,y)),
                                                 width:measured.width,height:measured.height))
                    }
                }
                let labelRect=candidates.first { rect in
                    let padded=rect.insetBy(dx:-4,dy:-4)
                    return !padded.intersects(runnerRect) && !crosses(padded,start,end)
                        && !crosses(padded,start,point(1,0))
                } ?? candidates[0]
                context.draw(resolved,at:.init(x:labelRect.midX,y:labelRect.midY))

                if let runner=context.resolveSymbol(id:"runner") {
                    context.draw(runner,in:runnerRect)
                }

            }
        } symbols: {
            Image(systemName:"flag.checkered").font(.system(size:15)).foregroundStyle(.secondary).tag("flag")
            Image(systemName:"figure.run").font(.system(size:16,weight:.medium)).foregroundStyle(Palette.green).tag("runner")
        }
        .frame(height:180)
        .accessibilityElement(children:.ignore)
        .accessibilityLabel("Remaining quota forecast")
        .accessibilityValue(accessibilitySummary(forecast))
        .help("Remaining quota decreases upward toward zero at the reset flag. Estimated spendable pool including planned tickets; redemption is manual.")
    }

    private func accessibilitySummary(_ forecast:QuotaForecast)->String {
        let total=String(format:"%.0f percent available. Ideal pace %.1f percent per day.",forecast.total,forecast.idealPace)
        guard let remaining=forecast.remainingAtReset,let pace=forecast.pace else { return total+" Your pace is still being sampled." }
        return total+String(format:" Your pace %.1f percent per day. ",pace)+(forecast.runsOutEarly ? "Quota used up before reset." : String(format:"%.0f percent left at reset.",remaining))
    }
}
