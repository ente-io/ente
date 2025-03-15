//
//  SlideshowWidget.swift
//  SlideshowWidget
//
//  Created by Prateek Sunal on 3/7/25.
//  Copyright © 2025 The Chromium Authors. All rights reserved.
//

import SwiftUI
import UIKit
import WidgetKit

private let widgetGroupId = "group.io.ente.frame.SlideshowWidget"

struct Provider: TimelineProvider {
    let X = 15
    let data = UserDefaults(suiteName: widgetGroupId)

    func placeholder(in _: Context) -> FileEntry {
        FileEntry(date: Date(), index: nil, imageData: nil)
    }

    func getSnapshot(in _: Context, completion: @escaping (FileEntry) -> Void) {
        let entry = FileEntry(date: Date(), index: nil, imageData: nil)
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [FileEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(second: 0), matchingPolicy: .nextTime,
            direction: .backward
        )!

        var totalSet =
            data?.integer(forKey: "totalSet")

        if totalSet != nil && totalSet! > 0 {
            totalSet = totalSet! > 5 ? 5 : totalSet!
            for offset in 0 ..< totalSet! {
                let randomInt = Int.random(in: 0 ..< totalSet!)
                let entryDate = Calendar.current.date(
                    byAdding: .minute, value: X * offset, to: currentDate
                )!
                let imageData =
                    data?.string(forKey: "slideshow_" + String(randomInt))
                let entry = FileEntry(date: entryDate, index: randomInt, imageData: imageData)
                entries.append(entry)
            }
        } else {
            let entry = FileEntry(date: Date(), index: -1, imageData: nil)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct FileEntry: TimelineEntry {
    let date: Date
    let index: Int?
    let imageData: String?
}

struct SlideshowWidgetEntryView: View {
    var entry: Provider.Entry
    let defaultBase64Image =
        "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"

    var body: some View {
        GeometryReader { geometry in
            if let imageData = entry.imageData,
               let uiImage = UIImage(contentsOfFile: imageData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // Make sure it doesn't overflow
            } else if let data = Data(base64Encoded: defaultBase64Image),
                      let uiImage = UIImage(data: data)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Color.gray // Fallback background
            }
        }
        .edgesIgnoringSafeArea(.all) // To cover entire widget area
    }
}

struct SlideshowWidget: Widget {
    let kind: String = "SlideshowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SlideshowWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SlideshowWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Slideshow Album")
        .description("This provides slideshow of memories.")
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    SlideshowWidget()
} timeline: {
    FileEntry(date: .now, index: nil, imageData: nil)
    FileEntry(date: .now, index: nil, imageData: nil)
}
