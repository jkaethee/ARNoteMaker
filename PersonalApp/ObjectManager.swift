//
//  ObjectManager.swift
//  PersonalApp
//
//  Created by Jathushan Kaetheeswaran on 2020-01-14.
//  Copyright © 2020 Jathushan Kaetheeswaran. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

// Struct to hold the model data
struct ObjectInfo {
    public var modelType: Int = 0
    public var modelPosition: SCNVector3 = SCNVector3(0,0,0)
    public var modelRotation: SCNVector4 = SCNVector4(0,0,0,0)
    public var description: String? = nil
}


// Main model manager class.
class ObjectManager {
    
    // to hold the scene details
    private var sceneView: ARSCNView!
    
    // arrays to hold the model data
    private var modelInfoArray: [ObjectInfo] = []
    private var modelNodeArray: [SCNNode] = []
    
    // variable that holds model path
    private var modelPath = "art.scnassets/ball.scn"
    
    private var textArray = [String] ()
    private var counter = 0
    
    // constructor that sets the scene
    init() {
    }
    
    public func setScene (view: ARSCNView) {
        sceneView = view
    }
    
    //add model to plane/mesh where reticle currently is, return the reticles global position
    public func addModelAtPose (node: SCNNode, index: Int, text: String) {
        
        // add node the storage data structures
        let newModel: ObjectInfo = ObjectInfo(modelType: index, modelPosition: node.position, modelRotation: node.rotation)
        textArray.append(text)
        // add model to model list and model node list
        modelInfoArray.append(newModel)
        modelNodeArray.append(node)
        
    }
    
    // turn the scn file into a node
    func getModel (index: Int) -> SCNNode {
        let node = SCNNode()
        if (index == -1){
        let fileScene = SCNScene(named: modelPath)
        for child in (fileScene!.rootNode.childNodes) {
            node.addChildNode(child)
            }
        }
        else {
            let words = textArray[counter]
            let text = SCNText(string: words, extrusionDepth: 0)
            text.firstMaterial?.diffuse.contents = UIColor.yellow
            text.firstMaterial?.isDoubleSided = false
            text.font = UIFont(name: "DamascusBold", size: 0.5)

            //3. Set It's Flatness To 0 So It Looks Smooth
            text.flatness = 0

            // Sets the position of the arbitrary node to where the user tapped on Scene#1 (the original scene)
            node.geometry = text
            node.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
            node.orientation = sceneView.pointOfView!.orientation
        }
        print ("created model from " + String(index))
        // add node to the scene
        sceneView.scene.rootNode.addChildNode(node)
        return node
    }
    
    // turn the model array into a json object
    func getModelInfoJSON() -> [[String: [String: String]]]
    {
        var modelInfoJSON: [[String: [String: String]]] = []
        
        if (modelInfoArray.count > 0)
        {
            for i in 0...(modelInfoArray.count-1)
            {
                modelInfoJSON.append(["model": ["type": "\(modelInfoArray[i].modelType)", "px": "\(modelInfoArray[i].modelPosition.x)",  "py": "\(modelInfoArray[i].modelPosition.y)",  "pz": "\(modelInfoArray[i].modelPosition.z)", "qx": "\(modelInfoArray[i].modelRotation.x)", "qy": "\(modelInfoArray[i].modelRotation.y)", "qz": "\(modelInfoArray[i].modelRotation.z)", "qw": "\(modelInfoArray[i].modelRotation.w)" ]])
            }
        }
        return modelInfoJSON
    }
    

    // Load shape array
    func loadModelArray(modelArray: [[String: [String: String]]]?) -> Bool {

        clearModels()
        print("CLEARED")
        if (modelArray == nil) {
            print ("Model Manager: No models in this map")
            return false
        }

        for item in modelArray! {
            let px_string: String = item["model"]!["px"]!
            let py_string: String = item["model"]!["py"]!
            let pz_string: String = item["model"]!["pz"]!
            
            let qx_string: String = item["model"]!["qx"]!
            let qy_string: String = item["model"]!["qy"]!
            let qz_string: String = item["model"]!["qz"]!
            let qw_string: String = item["model"]!["qw"]!
            
            let position: SCNVector3 = SCNVector3(x: Float(px_string)!, y: Float(py_string)!, z: Float(pz_string)!)
            let rotation: SCNVector4 = SCNVector4(x: Float(qx_string)!, y: Float(qy_string)!, z: Float(qz_string)!, w: Float(qw_string)!)
            let type: Int = Int(item["model"]!["type"]!)!
            
            // turn the scn file into a node
            let node = getModel(index: type)
            node.position = position
            node.rotation = rotation
            
            if(counter == textArray.count){
                textArray.append("temp")
                addModelAtPose(node: node, index: type, text: textArray[counter])
            }
            else{
            addModelAtPose(node: node, index: type, text: textArray[counter])
                print(textArray[counter])
             counter+=1
                }
            print ("Model Manager: Retrieved " + String(describing: type) + " type at position" + String (describing: position))
        }

        print ("Model Manager: retrieved " + String(modelInfoArray.count) + " models")
        return true
    }
    
    //clear shapes from scene
    func clearView() {
        for node in modelNodeArray {
            node.removeFromParentNode()
        }
    }
    
    // delete all models from scene and model lists
    func clearModels() {
        clearView()
        modelNodeArray.removeAll()
        modelInfoArray.removeAll()
    }
    
    // empties the text array()
    func clearArray(){
        textArray.removeAll()
    }
    
}
