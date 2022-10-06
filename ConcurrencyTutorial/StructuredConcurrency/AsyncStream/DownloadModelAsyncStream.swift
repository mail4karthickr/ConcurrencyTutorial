//
//  DownloadManager.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 04/10/22.
//

import Foundation

@MainActor
final class DownloadModel_AsyncStream: NSObject, ObservableObject, Sendable {
    static let urls = [
        URL(string: "https://www.objc.io/index.html")!,
        URL(string: "https://ftp.acc.umu.se/mirror/wikimedia.org/dumps/enwiki/20211101/enwiki-20211101-abstract.xml.gz")!
    ]
    
    private var delegate = DownloadDelegate_AsyncStream()

    let url: URL
      init(_ url: URL) {
          self.url = url
      }
    
    enum State {
        case notStarted
        case started
        case paused(resumeData: Data?)
        case done(URL)
    }
    
  @Published var progress: (bytesWritten: Int64, bytesExpected: Int64)?
    
  @MainActor @Published var state = State.notStarted
    private var downloadTask: URLSessionDownloadTask?
  
  @MainActor
  func start() async throws {
      let task: URLSessionDownloadTask
      if case let .paused(data?) = state {
          task = URLSession.shared.downloadTask(withResumeData: data)
      } else {
          task = URLSession.shared.downloadTask(with: url)
      }
      state = .started
      task.delegate = delegate
      let stream = AsyncStream<DownloadDelegate_AsyncStream.Event> { cont in
          delegate.onEvent = { event in
              cont.yield(event)
              if case .didFinish = event {
                  cont.finish()
              }
              if case .didCancel = event {
                  cont.finish()
              }
          }
      }
      task.resume()
      downloadTask = task
      /*
       The for loop iterates over each event from the delegate, and it suspends itself after each iteration. This goes on until the download finishes, after which the start method returns.
       */
      for await event in stream {
          switch event {
          case .didCancel:
              ()
          case .didFinish(let url):
              state = .done(url)
          case let .didWrite(bytesWritten: written, bytesExpected: expected):
              progress = (written, expected)
          }
      }
  }

    func pause() async {
        let data = await downloadTask?.cancelByProducingResumeData()
        state = .paused(resumeData: data)
    }
}

class DownloadDelegate_AsyncStream: NSObject, URLSessionDownloadDelegate {
    enum Event {
        case didCancel
        case didFinish(URL)
        case didWrite(bytesWritten: Int64, bytesExpected: Int64)
    }
    var onEvent: (Event) -> () = { _ in }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
         onEvent(.didFinish(location))
     }

     func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
         onEvent(.didWrite(bytesWritten: totalBytesWritten, bytesExpected: totalBytesExpectedToWrite))
     }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let n = error as? NSError, n.code == CFNetworkErrors.cfurlErrorCancelled.rawValue {
            onEvent(.didCancel)
        } else {
            print("Error", error) // todo
        }
    }
}
