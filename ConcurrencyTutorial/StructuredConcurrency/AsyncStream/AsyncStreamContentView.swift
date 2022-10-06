//
//  AsyncStreamUseCase.swift
//  ConcurrencyTutorial
//
//  Created by Karthick Ramasamy on 06/10/22.
//

import SwiftUI

enum AsyncStreamUseCase: String, CaseIterable {
    case asynStream = "AsyncStream"
    case asyncThrowingStream = "AsyncThrowingStream"
    case fileDownload = "FileDownload"
}

struct AsyncStreamContentView: View {
    var body: some View {
        List(AsyncStreamUseCase.allCases, id: \.self) { useCase in
            Text("\(useCase.rawValue)")
        }
    }
}

struct AsyncStreamUseCase_Previews: PreviewProvider {
    static var previews: some View {
        AsyncStreamContentView()
    }
}
