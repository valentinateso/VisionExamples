//
//  TextRecognitionView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 06/03/24.
//

import SwiftUI
import Vision

struct TextRecognitionView: View {
    @State private var presentPicker: Bool = false
    @State private var pickerImage: UIImage?
    @State private var recognizedText: String = ""

    var body: some View {
        ScrollView {
            VStack {
                if let image = pickerImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }

                Button(action: {
                    recognizedText = ""
                    presentPicker.toggle()
                }, label: {
                    Text("Choose a Picture")
                })
                .padding()

                Button(action: {
                    self.recognizeText()
                }, label: {
                    Text("Recognize Text")
                })
                .padding()

                Text(recognizedText)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .sheet(isPresented: $presentPicker, content: {
                ImagePicker(image: $pickerImage, imagePickerType: .photoLibrary)
            })
        }
    }
    
    func recognizeText() {
        ///Get Image Data
        guard let cgImage = pickerImage?.cgImage else { return }

        ///Create Vision Image Handler
        let visionImageRequestHandler = VNImageRequestHandler(cgImage: cgImage)

        ///Text Recognition Request
        let textRecognitionRequest = VNRecognizeTextRequest { request, error in

            ///Get Recognized Text Result
            guard let result = request.results as? [VNRecognizedTextObservation] else { return }

            ///Extract Text Data
            let stringArray = result.compactMap { result in
                result.topCandidates(1).first?.string
            }

            ///Show the recognized text in UI
            DispatchQueue.main.async {
                recognizedText = stringArray.joined(separator: "\n")
            }
        }

        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["en-US", "fr-FR"]

        ///Perform the Vision Request
        do {
            try visionImageRequestHandler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
    }
}
