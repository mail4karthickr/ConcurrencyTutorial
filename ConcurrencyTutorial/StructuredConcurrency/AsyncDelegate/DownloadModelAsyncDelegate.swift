//
//  DownloadManager.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 04/10/22.
//

import Foundation

/*
 1. Currently URLSession calls delegate methods on any queue - most likely a background queue.
 2. We wonder how Apple would bridge these calls to the world of structured concurrence — how would Apple design an API for that? One possibility is that it'd provide us with a stream of events. Although Swift already defines some event enums, it's not a very common pattern, especially not coming from Apple.
 3. Another possibility is that there will be some kind of asynchronous delegate protocol. A simplified version of such a protocol could look like this:
 4. It may look strange to require async methods on a delegate, since the caller of those methods probably isn't interested in awaiting their return. But defining a method as async has another effect: it creates the opportunity for a context switch. In other words, if we mark our delegate class as @MainActor, we can be sure that its async methods are executed on the main queue.
 5. To get an idea of how we'd be able to use this async protocol, let's see if we can make it work by forwarding the method calls from our own DownloadModelDelegate:
 */
protocol AsyncDownloadDelegate: AnyObject {
    func didFinishDownloading(location: URL) async
    func didWrite(bytesWritten: Int64, bytesExpected: Int64) async
}

@MainActor
final class DownloadModel_AsyncDelegate: NSObject, ObservableObject, Sendable {
    static let urls = [
        URL(string: "https://www.objc.io/index.html")!,
        URL(string: "https://ftp.acc.umu.se/mirror/wikimedia.org/dumps/enwiki/20211101/enwiki-20211101-abstract.xml.gz")!
    ]
    private var delegate = DownloadDelegate_AsyncDelegate()
    
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
  func start() {
      let task: URLSessionDownloadTask
      if case let .paused(data?) = state {
          task = URLSession.shared.downloadTask(withResumeData: data)
      } else {
          task = URLSession.shared.downloadTask(with: url)
      }
      state = .started
      task.delegate = delegate
      delegate.delegate = self
      task.resume()
      downloadTask = task
  }

    func pause() {
        Task {
            let data = await downloadTask?.cancelByProducingResumeData()
            state = .paused(resumeData: data)
        }
    }
}

extension DownloadModel_AsyncDelegate: AsyncDownloadDelegate {
    func didFinishDownloading(location: URL) async {
        state = .done(location)
    }
    
    func didWrite(bytesWritten: Int64, bytesExpected: Int64) async {
        progress = (bytesWritten, bytesExpected)
    }
}

class DownloadDelegate_AsyncDelegate: NSObject, URLSessionDownloadDelegate {
    weak var delegate: AsyncDownloadDelegate?

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task {
            await delegate?.didFinishDownloading(location: location)
        }
     }

     func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
     ) {
         Task {
             await delegate?.didWrite(
                bytesWritten: totalBytesWritten,
                bytesExpected: totalBytesExpectedToWrite
             )
         }
     }
}

