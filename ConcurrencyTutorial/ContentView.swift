//
//  ContentView.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 04/10/22.
//

import SwiftUI

enum UseCase: String, CaseIterable {
    case asyncStream = "AsyncStream"
    case asyncDelegate = "AsyncDelegate"
}

struct ContentView: View {
    var body: some View {
        List(UseCase.allCases, id: \.self) { useCase in
            Text(useCase.rawValue)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
