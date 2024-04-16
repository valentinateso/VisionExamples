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
    let frame: CGRect
    
    class VideoPreview: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
        ///Camera Session
        var session: AVCaptureSession?
        
        ///Layer to display Camera Feed
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        ///Layer to draw detected face rectangle
        private var faceLayers: [CAShapeLayer] = []
        
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
            
            ///Update the Preview Layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
            previewLayer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            ///Start the session
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
            print("AVCapture session is running now....\(previewLayer.frame)")
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
        
        func detectFaces(_ handler: VNImageRequestHandler) {
            
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<CameraView>) -> CameraView.UIViewType {
        let videoPreview = VideoPreview()
        videoPreview.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        videoPreview.backgroundColor = .black
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
            videoPreview.checkCameraPermission()
        }
        return videoPreview
    }
    
    func updateUIView(_ uiView: VideoPreview, context: UIViewRepresentableContext<CameraView>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let viewSession = uiView.session {
                print("camera: \(startCamera)")
                DispatchQueue.global(qos: .background).async {
                    _ = startCamera ? viewSession.startRunning() : viewSession.stopRunning()
                }
            }
        }
    }
}
