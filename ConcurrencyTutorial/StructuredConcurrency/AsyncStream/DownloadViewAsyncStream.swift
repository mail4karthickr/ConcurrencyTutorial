//
//  DownloadView.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 04/10/22.
//

import SwiftUI

struct DownloadView_AsyncStream: View {
    @ObservedObject var model: DownloadModel_AsyncStream

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
                    Task { [model] in
                        try await model.start()
                    }
                }
            case .started:
                HStack {
                    if model.progress == nil {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }
                    Button("Cancel") {
                        Task { [model] in
                            try await model.pause()
                        }
                    }
                }
            case .paused(resumeData: _):
                    Text("Paused...")
                    Button("Resume") {
                        Task { [model] in
                            try await model.start()
                        }
                    }
            case let .done(url):
                Text("Done: \(url)")
            }
        }
    }
}

struct DownloadContentView_AsyncStream: View {
    var body: some View {
        VStack {
            ForEach(DownloadModel_AsyncStream.urls, id: \.self) { url in
                DownloadView_AsyncStream(model: DownloadModel_AsyncStream(url))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
