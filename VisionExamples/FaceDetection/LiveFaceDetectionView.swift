//
//  LiveFaceDetectionView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 16/04/24.
//

import SwiftUI
import Zip

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

struct PlayButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(3)
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
    @State var movFile: URL? = nil
    
    var body: some View {
        GeometryReader{ geometry in
            VStack {
                CameraView(startCamera: $startCamera, csvFile: $csvFile, movFile: $movFile, frame: geometry.frame(in: .global))
                VStack {
                    Button {
                        startCamera = !startCamera
                    } label: {
                        Image(systemName: startCamera ? "stop.circle" : "play.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                    .buttonStyle(PlayButton())
                    
                    if let csvFile = csvFile, let movFile = movFile {
                        HStack {
                            ShareLink("Share", item: zip(files: [csvFile, movFile], name: csvFile.lastPathComponent.replacingOccurrences(of: ".csv", with: "")) ?? csvFile)
                                .buttonStyle(GrowingButton())
                            
                            Button {
                                moving = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save csv file localy")
                                }
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
                        }
                    }
                }
                .frame(height: 150)
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
    
    /// Create zip file from files passed as parameter
    /// - parameters:
    ///   - files: Files to zip
    ///   - name: Name of zip file
    ///   - progress: A progress closure called after unzipping each file in the archive. Double value betweem 0 and 1.
    /// - returns: URL of zip file if created, nil otherwise
    func zip(files: [URL], name: String, progress: ((_ progress: Double) -> ())? = nil) -> URL? {
        do {
            let fileManager = FileManager.default
            let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let zipFilePath = paths[0].appendingPathComponent("\(name).zip")
            try Zip.zipFiles(paths: files, zipFilePath: zipFilePath, password: nil, progress: progress)
            return zipFilePath
        }
        catch {
            print("Something went wrong, couldnt zip \(name)")
            return nil
        }
    }
}
