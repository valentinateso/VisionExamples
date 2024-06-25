//
//  LiveFaceDetectionView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 16/04/24.
//

import SwiftUI

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(.yellow)
            .foregroundStyle(.black)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct LiveFaceDetectionView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State var startCamera: Bool = false
    @State var moving: Bool = false
    @State var csvFile: URL? = nil

    var body: some View {
        GeometryReader{ geometry in
            VStack {
                CameraView(startCamera: $startCamera, csvFile: $csvFile, frame: geometry.frame(in: .global))
                
                HStack {
                    Button {
                        startCamera = !startCamera
                    } label: {
                        Text(startCamera ? "Stop" : "Start")
                    }
                    .buttonStyle(GrowingButton())
                    .frame(height: 100)
                    
                    if csvFile != nil {
                        Button("Save file") {
                            moving = true
                        }
                        .fileMover(isPresented: $moving, file: csvFile) { result in
                            switch result {
                            case .success(let file):
                                print(file.absoluteString)
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                        .buttonStyle(GrowingButton())
                        .frame(height: 100)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                    startCamera = false
                }, label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                })
            }
        }
    }
}
