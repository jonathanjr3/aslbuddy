//
//  MLCamera.swift
//  BSLBuddy
//
//  Created by Guest 2 on 16/11/2024.
//


import Foundation
import Vision

final class MLCamera: Camera {
    lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()
    
    var currentMLModel: HandPoseMLModel?
}
