// VeiloWidget.swift — ويدجات حقيقية على شاشة الآيفون الرئيسية (WidgetKit + SwiftUI)
// الخطوات: Xcode > File > New > Target > Widget Extension (اسمه VeiloWidget)
// ثم فعّل App Groups للتطبيق والويدجت بنفس الاسم: group.com.veilo.app
// التطبيق (Capacitor/Swift) يكتب الملخص بالدالة saveSnapshot بالأسفل.
// ملاحظة خصوصية: الملخص غير مشفّر، فاحفظ أرقامًا وعناوين فقط أو أخفِ العناوين.

import WidgetKit
import SwiftUI

let group = "group.com.veilo.app"

struct Snapshot: Codable {
    var notes = 0, todosDone = 0, todosTotal = 0
    var title = "Veilo", nextReminder = ""
    var week: [Int] = [0, 0, 0, 0, 0, 0, 0]
}

// يُستدعى من التطبيق كلما تغيّرت البيانات
func saveSnapshot(_ s: Snapshot) {
    if let d = try? JSONEncoder().encode(s) {
        UserDefaults(suiteName: group)?.set(d, forKey: "snap")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct Entry: TimelineEntry { let date: Date; let snap: Snapshot }

struct Provider: TimelineProvider {
    func load() -> Snapshot {
        guard let d = UserDefaults(suiteName: group)?.data(forKey: "snap"),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return Snapshot() }
        return s
    }
    func placeholder(in c: Context) -> Entry { Entry(date: .now, snap: Snapshot(notes: 12, todosDone: 3, todosTotal: 5, title: "ملاحظة مثال", nextReminder: "اليوم 6:00 م", week: [1, 3, 2, 5, 0, 4, 2])) }
    func getSnapshot(in c: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now, snap: load())) }
    func getTimeline(in c: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: .now, snap: load())], policy: .after(.now.addingTimeInterval(900))))
    }
}

struct VeiloView: View {
    @Environment(\.widgetFamily) var family
    let e: Entry
    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(e.snap.todosDone), in: 0...Double(max(e.snap.todosTotal, 1))) { Image(systemName: "checkmark") }
                .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading) { Text("Veilo").font(.headline); Text("\(e.snap.notes) ملاحظة").font(.caption) }
        case .systemMedium:
            HStack {
                big; Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label("التذكير القادم", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                    Text(e.snap.nextReminder.isEmpty ? "لا يوجد" : e.snap.nextReminder).font(.headline)
                    Spacer()
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(e.snap.week.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3).fill(.tint).frame(height: CGFloat(6 + e.snap.week[i] * 8))
                        }
                    }.frame(height: 50)
                }
            }
        default:
            big
        }
    }
    var big: some View {
        VStack(alignment: .leading) {
            Label("Veilo", systemImage: "lock.fill").font(.caption.bold()).foregroundStyle(.tint)
            Spacer()
            Text("\(e.snap.notes)").font(.system(size: 44, weight: .light))
            Text("ملاحظة مشفّرة").font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct VeiloWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VeiloWidget", provider: Provider()) { e in
            VeiloView(e: e).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Veilo")
        .description("ملاحظاتك ومهامك وتذكيراتك.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
