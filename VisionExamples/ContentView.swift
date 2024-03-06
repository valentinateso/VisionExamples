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
                NavigationLink(destination: TextRecognitionView(), label: { Text("OCR Text Recognition") })
                Divider()
                NavigationLink(destination: Text("To Do"), label: { Text("Face Recognition") })
                Spacer()
            }
            .padding()
            .navigationTitle("Vision Examples")
        }
    }
}

#Preview {
    ContentView()
}
