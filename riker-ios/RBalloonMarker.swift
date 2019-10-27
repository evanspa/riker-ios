//
//  RBalloonMarker.swift
//  riker-ios
//
//  Created by PEVANS on 4/26/17.
//  Copyright © 2017 Riker. All rights reserved.
//

import Foundation
import Charts

@objcMembers
@objc
open class RBalloonMarker: MarkerImage {
  open var isPercentage: Bool?
  open var uom: NSString?
  open var color: UIColor?
  open var arrowSize = CGSize(width: 0, height: 0) //CGSize(width: 15, height: 11)
  open var font: UIFont?
  open var textColor: UIColor?
  open var insets = UIEdgeInsets()
  open var minimumSize = CGSize()
  
  fileprivate var labelns: NSString?
  fileprivate var _labelSize: CGSize = CGSize()
  fileprivate var _paragraphStyle: NSMutableParagraphStyle?
  fileprivate var _drawAttributes = [NSAttributedStringKey : Any]()
  
  public init(uom: NSString, isPercentage: Bool, color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets)
  {
    super.init()
    self.isPercentage = isPercentage
    self.uom = uom
    self.color = color
    self.font = font
    self.textColor = textColor
    self.insets = insets
    
    _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
    _paragraphStyle?.alignment = .center
  }
  
  open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint
  {
    let size = self.size
    var point = point
    point.x -= size.width / 2.0
    point.y -= size.height
    return super.offsetForDrawing(atPoint: point)
  }
  
  open override func draw(context: CGContext, point: CGPoint)
  {
    if labelns == nil
    {
      return
    }
    
    let offset = self.offsetForDrawing(atPoint: point)
    let size = self.size
    
    var rect = CGRect(
      origin: CGPoint(
        x: point.x + offset.x,
        y: point.y + offset.y),
      size: size)
    rect.origin.x -= size.width / 2.0
    rect.origin.y -= size.height
    
    context.saveGState()
    
    if let color = color
    {
      context.setFillColor(color.cgColor)
      context.beginPath()
      context.move(to: CGPoint(
        x: rect.origin.x,
        y: rect.origin.y))
      context.addLine(to: CGPoint(
        x: rect.origin.x + rect.size.width,
        y: rect.origin.y))
      context.addLine(to: CGPoint(
        x: rect.origin.x + rect.size.width,
        y: rect.origin.y + rect.size.height - arrowSize.height))
      context.addLine(to: CGPoint(
        x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
        y: rect.origin.y + rect.size.height - arrowSize.height))
      context.addLine(to: CGPoint(
        x: rect.origin.x + rect.size.width / 2.0,
        y: rect.origin.y + rect.size.height))
      context.addLine(to: CGPoint(
        x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
        y: rect.origin.y + rect.size.height - arrowSize.height))
      context.addLine(to: CGPoint(
        x: rect.origin.x,
        y: rect.origin.y + rect.size.height - arrowSize.height))
      context.addLine(to: CGPoint(
        x: rect.origin.x,
        y: rect.origin.y))
      context.fillPath()
    }
    
    rect.origin.y += self.insets.top
    rect.size.height -= self.insets.top + self.insets.bottom
    
    UIGraphicsPushContext(context)
    
    labelns?.draw(in: rect, withAttributes: _drawAttributes)
    
    UIGraphicsPopContext()
    
    context.restoreGState()
  }
  
  open override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
  {
    setLabel(String(entry.y))
  }
  
  open func setLabel(_ label: String)
  {
    var suffix: NSString?
    suffix = nil
    var numValue = Float(label)
    if (self.isPercentage!) {
      numValue = numValue! * 100
      suffix = "%"
    } else {
      if (uom != nil) {
        suffix = NSString(format: " %@", uom!)
      }
    }
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = NumberFormatter.Style.decimal
    numberFormatter.maximumFractionDigits = 1
    let formattedLabel = numberFormatter.string(from: NSNumber(value: numValue!))
    if (suffix != nil) {
      labelns = NSString(format: "%@%@", formattedLabel!, suffix!)
    } else {
      labelns = formattedLabel! as NSString
    }
    
    _drawAttributes.removeAll()
    _drawAttributes[NSAttributedStringKey.font] = self.font
    _drawAttributes[NSAttributedStringKey.paragraphStyle] = _paragraphStyle
    _drawAttributes[NSAttributedStringKey.foregroundColor] = self.textColor
    
    _labelSize = labelns?.size(withAttributes: _drawAttributes) ?? CGSize.zero
    
    var size = CGSize()
    size.width = _labelSize.width + self.insets.left + self.insets.right
    size.height = _labelSize.height + self.insets.top + self.insets.bottom
    size.width = max(minimumSize.width, size.width)
    size.height = max(minimumSize.height, size.height)
    self.size = size
  }
}