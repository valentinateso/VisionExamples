//
//  LiveFaceDetectionView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 16/04/24.
//

import SwiftUI

struct LiveFaceDetectionView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State var startCamera: Bool = true

    var body: some View {
        GeometryReader{ geometry in
            CameraView(startCamera: $startCamera, frame: geometry.frame(in: .global))
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
