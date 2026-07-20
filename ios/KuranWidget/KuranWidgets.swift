// Kur'an'da ki Mesaj — iOS ana ekran widget'ları (WidgetKit).
// Tek dosya: Xcode'da Widget Extension target'ına eklemesi kolay olsun diye
// bundle + iki widget + tema birlikte. Veriyi Flutter home_widget'ın yazdığı
// App Group UserDefaults'tan okur (group.com.kurandakimesaj.app).
//
// Domain kuralı #2: Ayet widget'ında Arapça hat YOK — Amiri Quran fontu bu
// extension'a paketli olmadığından yalnızca Türkçe meal + kaynak gösterilir.

import WidgetKit
import SwiftUI

private let appGroup = "group.com.kurandakimesaj.app"

// ── Tema (uygulama zümrüt/altın paletiyle uyumlu) ──────────────────────────
private let emerald = Color(red: 0.043, green: 0.231, blue: 0.180)
private let gold = Color(red: 0.851, green: 0.698, blue: 0.416)
private let cream = Color(red: 0.953, green: 0.914, blue: 0.824)
private let muted = Color(red: 0.612, green: 0.702, blue: 0.659)

private extension View {
    // iOS 17+ containerBackground; eski sürümlerde düz arka plan.
    @ViewBuilder func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}

private func defaults() -> UserDefaults? { UserDefaults(suiteName: appGroup) }

// ── Ezan saati widget'ı ────────────────────────────────────────────────────
struct PrayerEntry: TimelineEntry {
    let date: Date
    let hijri: String
    let nextName: String
    let nextTime: String
    let location: String
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), hijri: "", nextName: "—", nextTime: "--:--", location: "")
    }
    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(read())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [read()], policy: .after(next)))
    }
    private func read() -> PrayerEntry {
        let d = defaults()
        return PrayerEntry(
            date: Date(),
            hijri: d?.string(forKey: "hijri_date") ?? "",
            nextName: d?.string(forKey: "prayer_next_name") ?? "—",
            nextTime: d?.string(forKey: "prayer_next_time") ?? "--:--",
            location: d?.string(forKey: "prayer_location") ?? ""
        )
    }
}

struct PrayerWidgetView: View {
    var entry: PrayerEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !entry.hijri.isEmpty {
                Text(entry.hijri).font(.caption2).bold().foregroundColor(gold)
            }
            Text("SIRADAKİ VAKİT").font(.system(size: 9)).tracking(1).foregroundColor(muted)
            HStack(alignment: .firstTextBaseline) {
                Text(entry.nextName).font(.title2).bold().foregroundColor(cream)
                Spacer()
                Text(entry.nextTime).font(.title2).bold().foregroundColor(gold)
                    .monospacedDigit()
            }
            if !entry.location.isEmpty {
                Text(entry.location).font(.caption2).foregroundColor(muted).lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "homeWidget://prayer"))
        .widgetBackground(emerald)
    }
}

struct PrayerWidget: Widget {
    let kind = "PrayerWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Ezan Saati")
        .description("Sıradaki namaz vakti ve hicri tarih.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Günün ayeti widget'ı ───────────────────────────────────────────────────
struct AyahEntry: TimelineEntry {
    let date: Date
    let meal: String
    let ref: String
}

struct AyahProvider: TimelineProvider {
    func placeholder(in context: Context) -> AyahEntry {
        AyahEntry(date: Date(), meal: "", ref: "")
    }
    func getSnapshot(in context: Context, completion: @escaping (AyahEntry) -> Void) {
        completion(read())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AyahEntry>) -> Void) {
        // Günde bir değişir; bir sonraki gün başında yenile.
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        completion(Timeline(entries: [read()], policy: .after(tomorrow)))
    }
    private func read() -> AyahEntry {
        let d = defaults()
        return AyahEntry(
            date: Date(),
            meal: d?.string(forKey: "ayah_meal") ?? "",
            ref: d?.string(forKey: "ayah_ref") ?? ""
        )
    }
}

struct AyahWidgetView: View {
    var entry: AyahEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GÜNÜN AYETİ").font(.system(size: 9)).tracking(1).bold().foregroundColor(gold)
            Text(entry.meal).font(.subheadline).foregroundColor(cream).lineLimit(4)
            Spacer(minLength: 0)
            Text(entry.ref).font(.caption).bold().foregroundColor(gold)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "homeWidget://ayah"))
        .widgetBackground(emerald)
    }
}

struct AyahWidget: Widget {
    let kind = "AyahWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AyahProvider()) { entry in
            AyahWidgetView(entry: entry)
        }
        .configurationDisplayName("Günün Ayeti")
        .description("Günün ayetinin meali.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// ── Bundle ─────────────────────────────────────────────────────────────────
@main
struct KuranWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
        AyahWidget()
    }
}
