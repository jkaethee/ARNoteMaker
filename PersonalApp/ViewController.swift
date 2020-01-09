//
//  ViewController.swift
//  PersonalApp
//
//  Created by Jathushan Kaetheeswaran on 2020-01-09.
//  Copyright © 2020 Jathushan Kaetheeswaran. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import PlacenoteSDK

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, PNDelegate {
    
    // Variables
    private var camManager : CameraManager? = nil  // Placenote CameraManager variable
    private var ptViz: FeaturePointVisualizer? = nil // Placenote Feature 
    
    
    // Outlets
  
    
    
    // Actions
    @IBAction func startMappingAndRenderSphere(_ sender: Any) {
        
        // Start Placenote mapping
        LibPlacenote.instance.startSession()
        
        
        
      }
    
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) {
        
    }
    
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        
    }
    
    func onLocalized() {
        
    }
    

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Add ViewController as a session delegate for ARKit
        sceneView.session.delegate = self
        
        // Add ViewController to be the multidelegate of PlacenoteSDK
        LibPlacenote.instance.multiDelegate += self
        
        // Allows PlacenoteSDK's CameraManager to manage the position of the ARKit camera
        if let camera: SCNNode = sceneView?.pointOfView {
            camManager = CameraManager(scene: sceneView.scene, cam: camera) // Pass in ARKit Scene and Camera Object
        }
        
        // Allows PlacenoteSDK's FeaturePointVisualizer to provide a visual for point clouds created by Placenote
        ptViz = FeaturePointVisualizer(inputScene: sceneView.scene)
        ptViz?.enablePointcloud()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
