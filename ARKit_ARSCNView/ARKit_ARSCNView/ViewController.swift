//
//  ViewController.swift
//  ARKit_ARSCNView
//
//  Created by 杨孟强 on 2017/9/3.
//  Copyright © 2017年 杨孟强. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var nodeBeganScale: Float!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        //设置代理(接下来我会介绍代理方法的使用)
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //显示统计信息，如fps
        sceneView.showsStatistics = true
        
        //-----------加载3D建模文件---------------------//
        //        // Create a new scene
        //        //用模型创建场景（scn格式文件是一个基于3D建模的文件，使用3DMax软件可以创建，这里系统有一个默认的3D飞机）
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //
        //        // Set the scene to the view
        //        //将场景设置到ARSCNView上显示
        //        sceneView.scene = scene
        
        //-----------加载几何图形--------------------------//
        //创建空场景
        let scene = SCNScene()
        
        //创建一个六面体几何模型，每面都为矩形，可选择圆形边缘和角，单位米
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0);
        
        //渲染
        //material渲染器
        let material = SCNMaterial()
        //        material.diffuse.contents = UIColor.orange
        material.diffuse.contents = UIImage(named: "brick")
        
        //如果几何具有与几何元素相同数量的材料，则材料索引对应于元素索引。对于具有比元素少的材料的几何，SceneKit通过计算该元素的材料数目的索引来确定每个元素的材料索引。例如，在具有六个元素和三个材质的几何体中，SceneKit将5使用索引处的材质在索引处渲染元素5 % 3 = 2。
        box.materials = [material];
        
        //创建节点 并将box加到节点上
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "boxNode"
        //设置节点位置。x,y,z轴位置
        boxNode.position = SCNVector3(0, 0, -0.2)
        
        //把节点添加到根节点上
        scene.rootNode.addChildNode(boxNode)
        //将场景设置到ARSCNView上显示
        sceneView.scene = scene;
        
        addGestureRecognizer()
    }
    
    //添加手势
    func addGestureRecognizer() {
        //添加滑动手势(用于移动和旋转模型)
        let PanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panFunc))
        sceneView.addGestureRecognizer(PanGestureRecognizer)
        
        //创建缩放手势(用于缩放模型)
        let PinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchFunc))
        sceneView.addGestureRecognizer(PinchGestureRecognizer)
    }
    
    @objc func panFunc(recognizer: UIPanGestureRecognizer) {
        
        //1.获取节点在空间中位置
        guard let node = self.sceneView.scene.rootNode.childNode(withName: "boxNode", recursively: true) else {
            return
        }
        let nodePosition = node.position
        
        
        //2.获取相机当前在空间中位置
        guard let cameraTransform = self.sceneView.session.currentFrame?.camera.transform else {
            return
        }
        let translation = cameraTransform.columns.3
        
        //3.获取本次滑动的距离
        let point = recognizer.translation(in: self.view)
        let pointX = Float(point.x / self.view.bounds.size.width) * 0.1
        let pointY = Float(point.y / self.view.bounds.size.height) * 0.1
        
        //4.设置新的位置 x(point.x+nodePosition.x)、y(-point.y+nodePosition.y)、z(point.y+nodePosition.z)
        let newNodePositionX = pointX + nodePosition.x;
        let newNodePositionY = -pointY + nodePosition.y;
        let newNodePositionZ = (translation.z-0.1 < pointY+nodePosition.z) ? (translation.z-0.1) : (pointY + nodePosition.z);//模型z坐标保持在距离摄像头0.1
        node.position = SCNVector3(newNodePositionX, newNodePositionY, newNodePositionZ)
        
        
        //旋转
        let angles = Float((node.eulerAngles.x > 6) ? (Float.pi / 32) : (node.eulerAngles.x + Float.pi / 32))
        node.eulerAngles = SCNVector3(angles, angles, 0)
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @objc func pinchFunc(recognizer: UIPinchGestureRecognizer) {
        
        //1.获取节点在空间中位置
        guard let node = self.sceneView.scene.rootNode.childNode(withName: "boxNode", recursively: true) else {
            return
        }
        
        if (recognizer.state == UIGestureRecognizerState.ended) {
            recognizer.scale = 1
        } else {
            
            //2.手势开始时保存node的scale
            if recognizer.state == UIGestureRecognizerState.began {
                self.nodeBeganScale = node.scale.x
            }
            
            //3.缩放
            //CGAffineTransform转换SCNVector3
            //转换具体参考
            //CGAffineTransform矩阵运算的原理 http://justsee.iteye.com/blog/1969933
            //node.scale SCNVector比例向量 https://developer.apple.com/documentation/scenekit/scnnode/1408050-scale
            //这里我只是使用了x方向的缩放
            let nodeScale = Float(recognizer.view!.transform.scaledBy(x: recognizer.scale, y: recognizer.scale).a) * self.nodeBeganScale
            node.scale = SCNVector3(nodeScale, nodeScale, nodeScale)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        /*
         创建一个追踪设备配置
         ARWorldTrackingConfiguration 跟踪设备的方向和位置以及检测设备相机所看到的实际表面的配置
         AROrientationTrackingConfiguration 仅跟踪设备方向的配置
         ARConfiguration AR会话配置的抽象基类
         */
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        //运行视图的会话
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        //暂停试图的会话
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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

