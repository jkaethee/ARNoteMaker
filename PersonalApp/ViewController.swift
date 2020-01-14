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
    private var camManager : CameraManager? = nil;  // Placenote CameraManager variable
    private var ptViz: FeaturePointVisualizer? = nil; // Placenote Feature
    private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())] //initializes array of maps
    private var placeObjectBool = false // bool for object toggle
    private var placeTextBool = false // bool for text toggle
    private var textNodeCounter = 0 // int counter for notes
    
    private var objectManager: ObjectManager = ObjectManager() // object manager
    private var loadedMetaData: LibPlacenote.MapMetadata = LibPlacenote.MapMetadata()
    
    // Outlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var beginButton: UIButton!
    @IBOutlet weak var saveMapButton: UIButton!
    @IBOutlet weak var loadMapButton: UIButton!
    @IBOutlet weak var placeObjectLabel: UILabel!
    @IBOutlet weak var placeObjectSwitch: UISwitch!
    @IBOutlet weak var placeTextLabel: UILabel!
    @IBOutlet weak var placeTextSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var clearMapButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    // Actions
    @IBAction func startMapping(_ sender: Any) {
        
        // Start Placenote mapping
        LibPlacenote.instance.startSession()
        self.statusLabel.text = "Starting mapping..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 5){
            self.statusLabel.text = ""
            }
        
        // Hide descriptive text
        beginButton.isHidden = true
        
        // Save button and clear map button appear
        clearMapButton.isHidden = false
        
        // Placement toggles and text appear
        placeObjectLabel.isHidden = false
        placeObjectSwitch.isHidden = false
        placeTextLabel.isHidden = false
        placeTextSwitch.isHidden = false
        textField.isHidden = false
      }
    
    @IBAction func placeObjectSwitch(_ sender: Any) {
        // Toggle Place Object switch on
        if placeObjectBool == false{
            placeObjectSwitch.isOn = true
            placeObjectBool = true
        }
        else{
            placeObjectSwitch.isOn = false
            placeObjectBool = false
        }
        
    }
    @IBAction func placeTextSwitch(_ sender: Any) {
        // Toggle Place Text switch on
              if placeTextBool == false{
                  placeTextSwitch.isOn = true
                  placeTextBool = true
              }
              else{
                  placeTextSwitch.isOn = false
                  placeTextBool = false
              }
    }
    
    @IBAction func saveMap(_ sender: Any) {

           //save the map and stop session
           LibPlacenote.instance.saveMap(
           savedCb: { (mapID: String?) -> Void in
            if (mapID != nil){
             self.statusLabel.text = "MapId: " + mapID!
             LibPlacenote.instance.stopSession()
             self.ptViz?.disablePointcloud()
            
            // save the map id user defaults
            UserDefaults.standard.set(mapID, forKey: "mapId")
            
            let mapMetaData = LibPlacenote.MapMetadataSettable()
            mapMetaData.name = "Workout Plan for " + WorkoutDayList.getDay()
                     
            self.statusLabel.text = "Saved Map: " + mapMetaData.name! //update UI
            var userdata: [String:Any] = [:]
            userdata["objectArray"] = self.objectManager.getModelInfoJSON()
            mapMetaData.userdata = userdata
                      
            if (!LibPlacenote.instance.setMetadata(mapId: mapID!, metadata: mapMetaData, metadataSavedCb: {(success: Bool) -> Void in})) {
                        print ("Failed to set map metadata")
                      }
             }
            else {
              NSLog("Failed to save map")
            }
           },
           uploadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                self.statusLabel.text = "Map Uploading..."
              if(completed){
                self.statusLabel.text = "Map upload done!!!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                         self.statusLabel.text = ""
                         }
              }
            })
        loadMapButton.isHidden = false
    }
    
    @IBAction func loadMap(_ sender: Any) {
      // get the saved map id
      let mapID = UserDefaults.standard.string(forKey: "mapId") ?? ""
      
      if (mapID == "")
      {
        self.statusLabel.text = "You have not saved a map yet. Nothing to load!"
        return
      }

      statusLabel.text = "Loading your saved map with ID: " + mapID
      
      // when we load the map, we're going to be hiding the feature points
      ptViz?.disablePointcloud()
      
      LibPlacenote.instance.loadMap(mapId: mapID,
          downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
            if (completed) {
              
              // start the Placenote session (this will start searching for localization)
              LibPlacenote.instance.getMetadata(mapId: mapID, getMetadataCb: { (success: Bool, metadata: LibPlacenote.MapMetadata) -> Void in
                if (success)
                {
                  print(" Meta data was downloaded : " + metadata.name!)
                  self.statusLabel.text = "Map and data are loaded. Point at your mapped area to relocalize"
                  
                  // storing meta data here so we can load it in the OnLocalized callback
                  self.loadedMetaData = metadata
                  LibPlacenote.instance.startSession()
                }
              })
            } else if (faulted) {
              print ("Couldnt load map: " + mapID)
              self.statusLabel.text = "Load error Map Id: " + mapID
            } else {
              print ("Progress: " + percentage.description)
              self.statusLabel.text = "Downloading map: " + percentage.description
            }
          }
      )
        }
    
    @IBAction func clearMap(_ sender: Any) {
       objectManager.clearModels()
        /*for node in sceneView.scene.rootNode.childNodes{
            node.removeFromParentNode()
        }*/
     self.statusLabel.text = "Clearing map..."
          DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                   self.statusLabel.text = ""
                   }
        textNodeCounter = 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first
            else {return}
        let result = sceneView.hitTest(touch.location(in: sceneView), types: ARHitTestResult.ResultType.featurePoint)
        let hitResult = result.first
        let hitTransform = SCNMatrix4.init(hitResult!.worldTransform)
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        
        if placeObjectBool == true{
            placeObject(position: hitVector)
            }
        if placeTextBool == true{
            placeText(position: hitVector)
        }
    }
    
    func placeObject(position: SCNVector3){
        // Instantiates a scene that contains the 3D model
        guard let modelScene = SCNScene(named: "art.scnassets/ball.scn") else {return}
        
        // Instantiantes an arbitrary node
        let node = SCNNode()
        
        // Adds all the child nodes from Scene#2 (the 3D model's child nodes) to the arbitrary node's childnode array
        for child in (modelScene.rootNode.childNodes){
            node.addChildNode(child)
        }
        // Sets the position of the arbitrary node to where the user tapped on Scene#1 (the original scene)
        node.position = position
        node.orientation = sceneView.pointOfView!.orientation
        // Adds the arbitrary node to Scene#1 where the user tapped
        sceneView.scene.rootNode.addChildNode(node)
        objectManager.addModelAtPose(node: node, index: 0)
    }

    func placeText(position: SCNVector3){
        textNodeCounter += 1
        let stringTextNodeCounter = String(textNodeCounter)
        
        // Instantiates an arbitrary node
        let textNode = SCNNode()
        
        let text = SCNText(string: stringTextNodeCounter + ". " + textField.text!, extrusionDepth: 0)
        text.firstMaterial?.diffuse.contents = UIColor.yellow
        text.firstMaterial?.isDoubleSided = false
        text.font = UIFont(name: "DamascusBold", size: 0.5)

        //3. Set It's Flatness To 0 So It Looks Smooth
        text.flatness = 0

        // Sets the position of the arbitrary node to where the user tapped on Scene#1 (the original scene)
        textNode.geometry = text
        textNode.position = position
        textNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        textNode.orientation = sceneView.pointOfView!.orientation

        // Adds the arbitrary node to Scene#1 where the user tapped
        sceneView.scene.rootNode.addChildNode(textNode)
        objectManager.addModelAtPose(node: textNode, index: 1)
    }
    
    func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) {
        
        if (LibPlacenote.instance.getMappingQuality() == LibPlacenote.MappingQuality.good) {
            saveMapButton.isHidden = false
        }
    }
    
    func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
        
    }
    
    func onLocalized() {
        statusLabel.text = "Map Relocalized!"
        
        // load the metadata objects into the scene
        let userdata = loadedMetaData.userdata as? [String:Any]
        
        if (self.objectManager.loadModelArray(modelArray: userdata?["objectArray"] as? [[String: [String: String]]])) {
          self.statusLabel.text = "Map relocalized! Look around to find your saved models."
            
        } else {
          self.statusLabel.text = "Map relocalized, but there was an error loading models"
        }
    }
    
    // send AR frame to placenote
    func session(_ session: ARSession, didUpdate: ARFrame) {
      LibPlacenote.instance.setARFrame(frame: didUpdate)
    }
    
    override func viewDidLoad() {
        
        // Hides the buttons
        saveMapButton.isHidden = true
        loadMapButton.isHidden = true
        clearMapButton.isHidden = true
        
        // Sets the switches to "OFF" and hides info
        placeObjectLabel.isHidden = true
        placeObjectSwitch.isOn = false
        placeObjectSwitch.isHidden = true
        placeTextLabel.isHidden = true
        placeTextSwitch.isOn = false
        placeTextSwitch.isHidden = true
        textField.isHidden = true
 
        super.viewDidLoad()
        // sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
       // Create a new scene
        let scene = SCNScene()
        
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
        
        // initialize the object manager
        objectManager.setScene(view: sceneView)
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
