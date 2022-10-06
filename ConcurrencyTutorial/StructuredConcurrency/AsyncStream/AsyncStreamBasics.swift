//
//  AsyncStreamBasics.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 06/10/22.
//

import SwiftUI

/*:
    1. AsyncStream are part of the concurrency framework introduced in Swift 5.5.
    2. Async streams allow you to replace existing code that is based on closures or Combine publishers.
    3. An AsyncStream is similar to the throwing variant but will never result in a throwing error. A non-throwing async stream finishes based on an explicit finished call or when the stream cancels.
    4. AsyncStream conforms to AsyncSequence, providing a convenient way to create an asynchronous sequence without manually implementing an asynchronous iterator. In particular, an asynchronous stream is well-suited to adapt callback- or delegation-based APIs to participate with async-await
 */
struct AsyncStreamBasics: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct AsyncStreamBasics_Previews: PreviewProvider {
    static var previews: some View {
        AsyncStreamBasics()
    }
}
