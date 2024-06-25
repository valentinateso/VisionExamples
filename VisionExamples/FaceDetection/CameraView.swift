//
//  CameraView.swift
//  VisionExamples
//
//  Created by Gaurav Kumar on 16/04/24.
//

import AVFoundation
import SwiftUI
import UIKit
import Vision

struct CameraView: UIViewRepresentable {
    typealias UIViewType = VideoPreview
    @Binding var startCamera: Bool
    @Binding var csvFile: URL?
    @Binding var movFile: URL?
    let frame: CGRect
    
    class VideoPreview: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
            print("Finish capturing video, Error: \(error?.localizedDescription ?? "None")")
        }
        
        ///Camera Session
        var session: AVCaptureSession?
        
        ///Layer to display Camera Feed
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        ///Layer to draw detected face rectangle
        private var faceLayers: [CAShapeLayer] = []
        
        var movieOutput = AVCaptureMovieFileOutput()
        
        var movieFileUrl: URL? = nil
        
        var csvFileUrl: URL? = nil
        var startTime: Double? = nil
        
        init() {
            self.session = AVCaptureSession()
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = self.bounds
        }
        
        ///Check Camera Permission
        func checkCameraPermission() {
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            DispatchQueue.main.async {
                if cameraAuthorizationStatus == .authorized {
                    self.configureSession()
                } else if cameraAuthorizationStatus == .denied {
                    print("Camera access denied🙅")
                } else {
                    self.requestCameraAccessForVideo()
                }
            }
        }
        
        func requestCameraAccessForVideo() {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.configureSession()
                    } else {
                        print("Can't help!! Camera permission denied🙅")
                    }
                }
            }
        }
        func appendLineToURL(fileURL: URL, line: String) {
            do {
                
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    // Create a file handle
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    
                    // Move to the end of the file
                    fileHandle.seekToEndOfFile()
                    
                    // Convert the line to data and write it to the file
                    if let data = "\(line)\n".data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    
                    // Close the file handle
                    fileHandle.closeFile()
                } else {
                    try "\(line)\n".write(to: fileURL, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Error writing to file: \(error.localizedDescription)")
            }
        }
        
        func configureSession() {
            ///Select the Front Camera as device and create input.
            guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let deviceInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
                print("No camera device input found.")
                return
            }
            
            guard let session else {
                print("session not initiated")
                return
            }
            
            ///Add device input to session
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            } else {
                print("couldn't add the device input to session.")
            }
            
            ///Video Output
            let videoOutput = AVCaptureVideoDataOutput()
            
            ///Create a serial dispatch queue used for sample buffer delegate as well as when a still image is captured.
            ///A serial dispatch queue makes sure that video frames will be delivered in order.
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
            
            ///Add video output to session
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            } else {
                print("couldn't add the device output to session.")
            }
            
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            } else {
                print("Can't add movie output.")
                return
            }
            
            ///Update the Preview Layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
            previewLayer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            
        }
        
        func stopSession() {
            self.session?.stopRunning()
            DispatchQueue.main.async {
                self.movieOutput.stopRecording()
            }
        }
        
        func startSession() {
            
            ///Start the session
            DispatchQueue.global(qos: .background).async {
                
                guard let session = self.session else {
                    print("session not initiated")
                    return
                }
                session.startRunning()
                
                let fileManager = FileManager.default
                
                // Get the URLs for the specified directory
                let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
                
                let timestamp = NSDate.timeIntervalSinceReferenceDate
                self.movieFileUrl = paths[0].appendingPathComponent("output-\(timestamp).mov")
                if let movieFileUrl = self.movieFileUrl {
                    try? fileManager.removeItem(at: movieFileUrl)
                }
                
                self.csvFileUrl = paths[0].appendingPathComponent("output-\(timestamp).csv")
                if let csvFileUrl = self.csvFileUrl {
                    try? fileManager.removeItem(at: csvFileUrl)
                }
                
                if let movieFileUrl = self.movieFileUrl {
                    self.movieOutput.startRecording(to: movieFileUrl, recordingDelegate: self)
                }
                
                if let csvFileUrl = self.csvFileUrl {
                    self.startTime = self.session?.synchronizationClock?.time.seconds
                    self.appendLineToURL(fileURL: csvFileUrl, line: "timestamp,yaw,pitch,roll")
                }
                
                
            }
            
            print("AVCapture session is running now....\(String(describing: self.previewLayer?.frame))")
        }
        
        ///Capture the video sample buffer and do the face detection
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("couldn't get pixel from sample buffer")
                return
            }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                print("couldn't create cgImage from pixel buffer")
                return
            }
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(connection.videoOrientation.rawValue))!
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            self.detectFaces(handler)
        }
        
        ///Start Face detection
        private func detectFaces(_ handler: VNImageRequestHandler) {
            let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
                DispatchQueue.main.async {
                    self.faceLayers.forEach { drawing in
                        drawing.removeFromSuperlayer()
                    }
                    if let observation = request.results as? [VNFaceObservation] {
                        self.handleFaceDetectionObservation(observation)
                    }
                }
            })
            do {
                try handler.perform([faceDetectionRequest])
            } catch {
                print("face detection fail, error: \(error)")
            }
        }
        
        private func handleFaceDetectionObservation(_ observations: [VNFaceObservation]) {
            
            let offset = ((self.session?.synchronizationClock?.time.seconds ?? -1.0) - (self.startTime ?? 0.0))
            
            if observations.count == 0 {
                if let csvFileUrl = self.csvFileUrl {
                    let line = "\(offset),,"
                    self.appendLineToURL(fileURL: csvFileUrl, line: line)
                }
                return
            }
            
            for observation in observations {
                let yaw = observation.yaw ?? 0
                let pitch = observation.pitch ?? 0
                let roll = observation.roll ?? 0
                
                let line = "\(offset),\(yaw),\(pitch),\(roll)"
                if let csvFileUrl = self.csvFileUrl {
                    self.appendLineToURL(fileURL: csvFileUrl, line: line)
                }

                if let previewLayer = self.previewLayer {
                    let faceRectConverted = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
                    let faceRectPath = CGPath(rect: faceRectConverted, transform: nil)
                    
                    let faceLayer = CAShapeLayer()
                    faceLayer.path = faceRectPath
                    faceLayer.fillColor = UIColor.clear.cgColor
                    faceLayer.strokeColor = UIColor.green.cgColor
                    
                    self.faceLayers.append(faceLayer)
                    self.layer.addSublayer(faceLayer)
                }
            }
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<CameraView>) -> CameraView.UIViewType {
        let videoPreview = VideoPreview()
        videoPreview.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        videoPreview.backgroundColor = .black
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
            videoPreview.checkCameraPermission()
            self.csvFile = videoPreview.csvFileUrl
            self.movFile = videoPreview.movieFileUrl
        }
        return videoPreview
    }
    
    func updateUIView(_ uiView: VideoPreview, context: UIViewRepresentableContext<CameraView>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("camera: \(startCamera)")
            DispatchQueue.global(qos: .background).async {
                _ = startCamera ? uiView.startSession() : uiView.stopSession()
                self.csvFile = uiView.csvFileUrl
                self.movFile = uiView.movieFileUrl
            }
        }
    }
}
