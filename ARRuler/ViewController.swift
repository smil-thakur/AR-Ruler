//
//  ViewController.swift
//  ARRuler
//
//  Created by Smil on 17/06/23.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var points:[SCNNode] = [];
    
    @IBOutlet weak var unitDisp: UIBarButtonItem!
    
    var units = ["m" , "cm" , "in"]
    
    var unitIdx = 0;
    
    var dispTexts:[SCNText] = [];
    
    var dispTextNodes:[SCNNode] = [];
    
    var lineNodes:[SCNNode] = [];
    
    func getLengthInCm(lengthInMeter:Float) -> Float{
        
        return Float(Int((lengthInMeter*100)*100)) / 100.0;
        
    }
    
    func getLengthInInches(lengthInMeter:Float) -> Float{
        
        return Float(Int((lengthInMeter * 39.3701)*100)) / 100.0;
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        unitDisp.title = units[unitIdx];
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints];
    }
    
    @IBAction func changeUnit(_ sender: UIBarButtonItem) {
        
        
        if(unitIdx + 1 == units.count){
            unitIdx = 0;
        }
        else{
            unitIdx += 1;
        }
        
        unitDisp.title = units[unitIdx];
       
        
        for i in stride(from: 0, to: dispTexts.count, by: 1){
                        
            if(units[unitIdx] == "m"){
                
                if let length = Float(dispTexts[i].string as! String){
                    
                    let res = Float(Int((0.0254 * length)*100)) / 100.0;
                    
                    dispTexts[i].string = "\(res)"
                   
                }
                
            }
            else if(units[unitIdx] == "cm"){
                
                if let length = Float(dispTexts[i].string as! String){
                    
                    let res = Float(Int((100*length)*100)) / 100.0;
                    
                    dispTexts[i].string = "\(res)"
                   
                }
                
                
            }
            else{
                
                if let length = Float(dispTexts[i].string as! String){
                    
                    let res = Float(Int((0.393701 * length)*100)) / 100.0;
                    
                    dispTexts[i].string = "\(res)"
                   
                }
                
            }
            
        }
        
    }
    
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
        
        
        
        for line in lineNodes{
            line.removeFromParentNode();
        }
        
        for disptext in dispTextNodes {
            disptext.removeFromParentNode();
        }
        
        for point in points {
            point.removeFromParentNode();
        }
        
        lineNodes = [];
        dispTextNodes = [];
        points = [];
        
        print(points)
    }
    
    
    func addDot(at:ARHitTestResult){
        
        
        let sphere = SCNSphere(radius: 0.002);
        
        let sphereNode = SCNNode();
        
        sphereNode.position = SCNVector3(x:at.worldTransform.columns.3.x ,y: at.worldTransform.columns.3.y,z:at.worldTransform.columns.3.z);
        
        let material  = SCNMaterial();
        
        material.diffuse.contents = UIColor.red;
        
        sphere.materials = [material]
        
        sphereNode.geometry = sphere
        
        sceneView.scene.rootNode.addChildNode(sphereNode);
        
        points.append(sphereNode);
        
        print(points)
        
        if( points.count >= 2 ){
            
            calculate()
            
        }
        
        
    }
    
    func calculate(){
        
        

        
        for i in stride(from: 0, to: points.count, by: 1){
            for j in stride(from: i + 1, to: points.count, by: 1){
                let start = points[i];
                let end = points[j];
                
                print(start.position);
                print(end.position);
                
                let a  = end.position.x - start.position.x
                let b  = end.position.y - start.position.y
                let c = end.position.z - start.position.z;
                
                var distance = sqrt(a * a + b * b + c * c);
                print(distance)

                distance = Float(Int(distance*100)) / 100.0;
                
                if(units[unitIdx] == "cm"){
                    distance = getLengthInCm(lengthInMeter: distance)
                }
                if(units[unitIdx] == "in"){
                    distance = getLengthInInches(lengthInMeter: distance)
                }
                
                showText(text: "\(distance)", start: start.position, end: end.position)
                showLine(start: start.position, end: end.position);
            }
        }
        
    }
    
    
    
    
    func showLine(start:SCNVector3 , end:SCNVector3){
        
        let lineNode = SCNNode()

        let vertices: [SCNVector3] = [start, end]
        let vertexSource = SCNGeometrySource(vertices: vertices)

        let indices: [UInt16] = [0, 1]
        let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
        let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<UInt16>.size)

        let lineGeometry = SCNGeometry(sources: [vertexSource], elements: [element])
        lineNode.geometry = lineGeometry

        sceneView.scene.rootNode.addChildNode(lineNode)
        lineNodes.append(lineNode)
        
    }
    
    func showText(text:String , start:SCNVector3 , end:SCNVector3){
        
        let x = (start.x + end.x)/2;
        let y = (start.y + end.y)/2;
        let z = (start.z + end.z)/2;
        
        let dispText = SCNText(string: text, extrusionDepth: 1.0);
        
        
        
        dispText.firstMaterial?.diffuse.contents = UIColor.red
        
        let dispTextNode = SCNNode(geometry: dispText);
        
        dispTextNode.position = SCNVector3(x,y,z)
        
        dispTextNode.scale = SCNVector3(0.001, 0.001, 0.001);
        
        
        sceneView.scene.rootNode.addChildNode(dispTextNode);
        dispTexts.append(dispText);
        dispTextNodes.append(dispTextNode);
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touchLocation  = touches.first?.location(in: sceneView) {
            
            let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
            
            if let hitResult = hitTestResults.first{
                addDot(at: hitResult);
                
            }
            
        }
        
        
        
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

}
