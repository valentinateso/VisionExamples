//
//  ContentView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 05/03/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                NavigationLink(destination: LiveFaceDetectionView(), label: { Text("Face Recognition") })
                Spacer()
            }
            .padding()
            .navigationTitle("Vision Examples")
        }
    }
}
