//
//  ViewController.swift
//  Nebula
//
//  Created by Simon Gladman on 08/03/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

//
// Based on http://glslsandbox.com/e#31308.0

import UIKit
import GLKit

class ViewController: UIViewController
{
    var time: CGFloat = 1
    var touchPosition = CIVector(x: 0, y: 0)
    
    let imageView = OpenGLImageView()
    
    lazy var nebulaKernel: CIColorKernel =
    {
        let nebulaShaderPath = NSBundle.mainBundle().pathForResource("NebulaShader", ofType: "cikernel")
        
        guard let path = nebulaShaderPath,
            code = try? String(contentsOfFile: path),
            kernel = CIColorKernel(string: code) else
        {
            fatalError("Unable to build nebula shader")
        }
        
        return kernel
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        
        let displayLink = CADisplayLink(target: self, selector: Selector("step"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    // MARK: Touch Handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let locationInView = touches.first?.locationInView(view) else
        {
            return
        }
        
        touchPosition = CIVector(x: view.frame.height / 2 - locationInView.y,
            y: view.frame.width / 2 - locationInView.x)
    }
    
    // MARK: Step
    
    func step()
    {
        time += 0.01
        
        let resolution = CIVector(x: view.frame.width, y: view.frame.height)
        
        let arguments = [time, touchPosition, resolution]
        
        let image = nebulaKernel.applyWithExtent(view.bounds, arguments: arguments)
        
        imageView.image = image
    }
    
    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
}

// -----

class OpenGLImageView: GLKView
{
    let eaglContext = EAGLContext(API: .OpenGLES2)
    
    lazy var ciContext: CIContext =
    {
        [unowned self] in
        
        return CIContext(EAGLContext: self.eaglContext,
            options: [kCIContextWorkingColorSpace: NSNull()])
        }()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame, context: eaglContext)
        
        context = self.eaglContext
        delegate = self
    }
    
    override init(frame: CGRect, context: EAGLContext)
    {
        fatalError("init(frame:, context:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// The image to display
    var image: CIImage?
        {
        didSet
        {
            setNeedsDisplay()
        }
    }
}

extension OpenGLImageView: GLKViewDelegate
{
    func glkView(view: GLKView, drawInRect rect: CGRect)
    {
        guard let image = image else
        {
            return
        }
        
        let targetRect = image.extent.aspectFitInRect(
            target: CGRect(origin: CGPointZero,
                size: CGSize(width: drawableWidth,
                    height: drawableHeight)))
        
        let ciBackgroundColor = CIColor(
            color: backgroundColor ?? UIColor.whiteColor())
        
        ciContext.drawImage(CIImage(color: ciBackgroundColor),
            inRect: CGRect(x: 0,
                y: 0,
                width: drawableWidth,
                height: drawableHeight),
            fromRect: CGRect(x: 0,
                y: 0,
                width: drawableWidth,
                height: drawableHeight))
        
        ciContext.drawImage(image,
            inRect: targetRect,
            fromRect: image.extent)
    }
}

extension CGRect
{
    func aspectFitInRect(target target: CGRect) -> CGRect
    {
        let scale: CGFloat =
        {
            let scale = target.width / self.width
            
            return self.height * scale <= target.height ?
                scale :
                target.height / self.height
        }()
        
        let width = self.width * scale
        let height = self.height * scale
        let x = target.midX - width / 2
        let y = target.midY - height / 2
        
        return CGRect(x: x,
            y: y,
            width: width,
            height: height)
    }
}
