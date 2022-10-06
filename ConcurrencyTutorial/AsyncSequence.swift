//
//  AsyncSequence.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 04/10/22.
//

import Foundation

/*
 You work with the Sequence protocol all the time: arrays, dictionaries, strings, ranges and Data are all sequences. They come with a lot of convenient methods, like next(), contains(), filter() and more. Looping over a sequence uses its built-in iterator and stops when the iterator returns nil.
 The AsyncSequence protocol works like Sequence, but an asynchronous sequence returns each element asynchronously (duh!). You can iterate over its elements asynchronously as more elements become available over time.
 You await each element, so the sequence can suspend while getting or calculating the next value.
 The sequence might generate elements faster than your code can use them: One kind of AsyncStream buffers its values, so your app can read them when it needs them.
 AsyncSequence provides language support for asynchronously processing collections of data. There are built-in AsyncSequences like NotificationCenter.Notifications, URLSession.bytes(from:delegate:) and its subsequences lines and characters. And you can create your own custom asynchronous sequences with AsyncSequence and AsyncIteratorProtocol or use AsyncStream.
 */

/*
 To familiarize ourselves with the concept, we want to see how we can read a large file without a spike in memory usage. For this, we've downloaded a Wikipedia dump in the form of compressed XML. In theory, we should be able to use AsyncSequence to read bytes or chunks of bytes instead of having to load the entire file at once.
 */

/*
    1. We will read a large file synchronlusly and compare its performance with async load.
    2. The below example loads and iterates a 100MB file line by line.
    3. In this approach, 100MB data is kept in memory untill all the lines are iterated.
    4. The peak memoer usage is 250MB and it took approx a second.
 */

func sample() throws {
    let start = Date.now
    let url = Bundle.main.url(forResource: "enwik8", withExtension: "xml")!
    let str = try String(contentsOf: url)
    var counter = 0
    str.enumerateLines { line, _ in
        counter += 1
    }
    print(counter)
    print("Duration: \(Date.now.timeIntervalSince(start))")
}

/*
    1. In this approach we will load the data asynchronously using FileHandle.
    2. Filehandle.butes returns an async sequence, so we have to wait until a byte is received.
    3. bytes.lines method accumulates the recevied bytes and wait untill the bytes for a line is received.
    4. Since the data reading happens in chunks, the memory usage would stay the same.
 */

func sampleAsync() async throws {
    let start = Date.now
    let url = Bundle.main.url(forResource: "enwik8", withExtension: "xml")!
    var counter = 0
    let fileHandle = try FileHandle(forReadingFrom: url)
    for try await _ in fileHandle.bytes.lines {
        counter += 1
    }
    print(counter)
    print("Duration: \(Date.now.timeIntervalSince(start))")
}

/*
    #Compressed data
    1. We are going to decompress a compressed file.
    2. enwik8.zlib file present in the project folder is a compressed file. We are going to decmpress it using the helper func present in the compression.swift file.
    3. The decompress method expects a chunk of data, so we have to create chunks from the .zlib file and feed the chunk to the decompress method.
    4. We will create an async sequence called chunked, which will take base sequence of bytes i.e UInt8 and a chunk size.
    5. For now, we default the chunk size to the buffer size of the Compressor wrapper.
    6. To conform this to AsyncSequence, we need to create an AsyncIterator.
 */

struct Chunked<Base: AsyncSequence>: AsyncSequence where Base.Element == UInt8 {
    var base: Base
    var chunkSize: Int = Compressor.bufferSize
    typealias Element = Data
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var chunkSize: Int
        
        mutating func next() async throws -> Data? {
            var result = Data()
            while let element = try await base.next() {
                result.append(element)
                if result.count == chunkSize { return result }
            }
            return result.isEmpty ? nil : result
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator(), chunkSize: chunkSize)
    }
}

/*
    A helper to convert sequence into a chunked.
 */

extension AsyncSequence where Element == UInt8 {
    var chunked: Chunked<Self> {
        Chunked(base: self)
    }
}

/*
    1. The below example uses the chunked property created above to get the chunk of data to decompress.
 */

func sampleDecompress() async throws {
    let start = Date.now
    let url = Bundle.main.url(forResource: "enwik8", withExtension: "zlib")!
    var counter = 0
    let fileHandle = try FileHandle(forReadingFrom: url)
    for try await _ in fileHandle.bytes.chunked {
        counter += 1
    }
    print(counter)
    print("Duration: \(Date.now.timeIntervalSince(start))")
}

/*
    #Decompressing data chunks
    1. We will creata an another async sequence which will take compressed chunk of data as input and decompress it using the compressor instance.
    2.
 */
struct Compressed<Base: AsyncSequence>: AsyncSequence where Base.Element == Data {
    var base: Base
    var method: Compressor.Method
    typealias Element = Data

    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var compressor: Compressor

        mutating func next() async throws -> Data? {
            if let chunk = try await base.next() {
                return try compressor.compress(chunk)
            } else {
               let result = try compressor.eof()
               return result.isEmpty ? nil : result
            }
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        let c = Compressor(method: method)
        return AsyncIterator(base: base.makeAsyncIterator(), compressor: c)
    }
}

/*
 Like before, we write an extension with a helper to create a Compressed sequence out of a Data sequence.
 */
extension AsyncSequence where Element == Data {
    var decompressed: Compressed<Self> {
        Compressed(base: self, method: .decompress)
    }
}

/*
    1. No we can append .decompressed to our chunked data sequence, and then we process the compressed file.
    2. No we can decode these chunks into strings to see the data is being decompressed correctly.
    3. Next, we will create an another sequence, flatten, to combine the chunks back into bytes.
 */

func sampleDecompressed() async throws {
    let start = Date.now
    let url = Bundle.main.url(forResource: "enwik8", withExtension: "zlib")!
    var counter = 0
    let fileHandle = try FileHandle(forReadingFrom: url)
    for try await chunk in fileHandle.bytes.chunked.decompressed {
        print(chunk)
        counter += 1
    }
    print(counter)
    print("Duration: \(Date.now.timeIntervalSince(start))")
}

/*
    1. We write a new sequence, flattened which will read the bytes and produce a sequence of individual byes.
    2. We make the flattened more generic by taking in an async sequence of any sequence.
 */

struct Flattened<Base: AsyncSequence>: AsyncSequence where Base.Element: Sequence {
    var base: Base
    typealias Element = Base.Element.Element
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var buffer: Base.Element.Iterator?

        mutating func next() async throws -> Element? {
            if let el = buffer?.next() {
                return el
            }
            buffer = try await base.next()?.makeIterator()
            guard buffer != nil else { return nil }
            return try await next()
        }
    }
    
    func makeAsyncIterator() ->  AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
}

/*
 We write a flattened property that wraps an AsyncSequence of Sequences in a Flattened sequence:
 */
extension AsyncSequence where Element: Sequence {
    var flattened: Flattened<Self> {
        Flattened(base: self)
    }
}

/*
 This loop is doing a lot of work: reading data from a file, decompressing it, chunking bytes into lines, and decoding strings. And this all happens in a streaming fashion, keeping the memory usage at a constant ~60 MB.
 */

func sampleFlattened() async throws {
    let start = Date.now
    let url = Bundle.main.url(forResource: "enwik8", withExtension: "zlib")!
    var counter = 0
    let fileHandle = try FileHandle(forReadingFrom: url)
    for try await line in fileHandle.bytes.chunked.decompressed.flattened.lines {
        print(line)
        counter += 1
    }
    print(counter)
    print("Duration: \(Date.now.timeIntervalSince(start))")
}

/*
  #Parsing XML data
    1. Instead of DOM parsing where the entire XML structure is loaded into memory - we want to do event based parsing.
    2. With NSXMLParser we cannot control how it reads data, so we cant integrate it into our AsyncSequence model.
    3. However, libxml2, available on iOS, is a C library with almost the same API as NSXMLParser, and it allows us to control how data is fed into it.
    4. We've written a wrapper around libxml2 function calls, and we've added it to the project.
 */
struct XMLEvents<Base: AsyncSequence>: AsyncSequence where Base.Element == Data {
    var base: Base
    typealias Element = XMLEvent
    
    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        let parser = PushParser()
        var buffer: [XMLEvent] = []
        
        mutating func next() async throws -> Element? {
            if !buffer.isEmpty {
                return buffer.removeFirst()
            }
            if let data = try await base.next() {
                var newEvents: [XMLEvent] = []
                parser.onEvent = { event in
                    newEvents.append(event)
                }
                parser.process(data)
                buffer = newEvents
                return try await next()
            }
            parser.finish()
            return nil
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
}

/*
 Then we add a property to create an XMLEvents sequence out of a Data sequence:
 */
extension AsyncSequence where Element == Data {
    var xmlEvents: XMLEvents<Self> {
        XMLEvents(base: self)
    }
}

/*
 we remove the flattening from our pipeline, and we use the above xmlEvents sequence instead.
 */
func sampleXMLEvents() async throws {
    let start = Date.now
    let url = Bundle.main.url(forResource: "enwik8", withExtension: "zlib")!
    var counter = 0
    let fileHandle = try FileHandle(forReadingFrom: url)
    for try await event in fileHandle.bytes.chunked.decompressed.xmlEvents {
        guard case let .didStart(name) = event else { continue }
        print(name)
        counter += 1
    }
    print(counter)
    print("Duration: \(Date.now.timeIntervalSince(start))")
}
