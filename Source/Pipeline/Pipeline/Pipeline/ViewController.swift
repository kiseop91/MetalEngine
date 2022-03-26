//
//  ViewController.swift
//  Pipeline
//
//  Created by 김기섭 on 2022/03/26.
//
import MetalKit
import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard!")
        }
        
        renderer = Renderer(metalView: metalView)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var renderer : Renderer?
}

