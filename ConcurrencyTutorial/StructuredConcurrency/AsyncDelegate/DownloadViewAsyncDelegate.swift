//
//  DownloadView.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 04/10/22.
//

import SwiftUI

struct DownloadView_AsyncDelegate: View {
    @ObservedObject var model: DownloadModel_AsyncDelegate

    var body: some View {
        VStack {
            Text("\(model.url)")
            if let p = model.progress, p.bytesExpected > 0 {
                ProgressView("Progress", value: Double(p.bytesWritten), total: Double(p.bytesExpected))
                    .progressViewStyle(.linear)
            }
            switch model.state {
            case .notStarted:
                Button("Start") {
                    model.start()
                }
            case .started:
                HStack {
                    if model.progress == nil {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }
                    Button("Cancel") {
                        model.pause()
                    }
                }
            case .paused(resumeData: _):
                    Text("Paused...")
                    Button("Resume") {
                        model.start()
                    }
            case let .done(url):
                Text("Done: \(url)")
            }
        }
    }
}

struct DownloadContentView_AsyncDelegate: View {
    var body: some View {
        VStack {
            ForEach(DownloadModel_AsyncDelegate.urls, id: \.self) { url in
                DownloadView_AsyncDelegate(model: DownloadModel_AsyncDelegate(url))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
