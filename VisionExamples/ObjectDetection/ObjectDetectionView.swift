//
//  ObjectDetectionView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 24/04/24.
//

import SwiftUI
import Vision

struct ObjectDetectionView: View {
    @State private var isImagePickerPresented: Bool = false
    @State private var showResultSheet: Bool = false
    @State private var capturedImage: UIImage?
    @State private var detectedObject: [Observation] = []
    let model = try! YOLOv3(configuration: MLModelConfiguration())
    
    var body: some View {
        VStack {
            Button("Take a Picture") {
                isImagePickerPresented.toggle()
            }
            .sheet(isPresented: $isImagePickerPresented, onDismiss: loadImage, content: {
                ImagePicker(image: self.$capturedImage, imagePickerType: .camera)
                    .ignoresSafeArea()
            })
            .sheet(isPresented: $showResultSheet, content: {
                VStack(content: {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 300)
                            .overlay {
                                GeometryReader { geometry in
                                    Path { path in
                                        for observation in detectedObject {
                                            path.addRect(VNImageRectForNormalizedRect(observation.boundingBox,
                                                                                      Int(geometry.size.width),
                                                                                      Int(geometry.size.height)))
                                        }
                                    }
                                }
                            }
                    }
                    if !detectedObject.isEmpty {
                        List(detectedObject, id: \.label) { item in
                            HStack {
                                Text(item.label.capitalized)
                                Spacer()
                                Text("\(item.confidence * 100, specifier: "%.2f")%")
                            }
                        }
                    } else {
                        VStack {
                            Text("Nothing could be detected")
                            Button("Wanna try again?") {
                                capturedImage = nil
                                detectedObject = []
                                showResultSheet.toggle()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                })
                .padding(.all)
            })
        }
    }

    func loadImage() {
        guard let vnCoreMLModel = try? VNCoreMLModel(for: model.model) else { return }
        let request = getVNCoreMLRequest(vnCoreMLModel)
        guard let image = capturedImage, let pixelBuffer = VisionHelper().convertToCVPixelBuffer(newImage: image) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        do {
            try requestHandler.perform([request])
            showResultSheet.toggle()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    func getVNCoreMLRequest(_ vnCoreMLModel: VNCoreMLModel) -> VNCoreMLRequest {
        return VNCoreMLRequest(model: vnCoreMLModel) { result, error in
            guard let objects = result.results as? [VNRecognizedObjectObservation] else { return }
            detectedObject = objects.map { object in
                guard let label = object.labels.first?.identifier else {
                    return Observation(label: "", confidence: VNConfidence.zero, boundingBox: .zero)
                }
                let confidence = object.labels.first?.confidence ?? 0.0
                let boundingBox = object.boundingBox
                return Observation(label: label, confidence: confidence, boundingBox: boundingBox)
            }
        }
    }
}

struct Observation {
    let label: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}
