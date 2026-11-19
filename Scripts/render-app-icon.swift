#!/usr/bin/env swift
// Renders the app icon into the asset catalog of the app.
//
// Usage: swift Scripts/render-app-icon.swift
//
// The three variants (light, dark, tinted) are drawn from the numbers of the icon sources
// `icon-light.svg`, `icon-dark.svg` and `icon-mono.svg`, which use a canvas of 512 units.
// Every variant becomes an opaque, full-bleed square of 1024 pixels without a rounded mask;
// the system cuts the corners itself.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// One line of an icon, in the units of the source canvas.
struct Stroke {
    let from: CGPoint
    let to: CGPoint
    let color: UInt32
}

/// A circle of an icon that is filled, or drawn as a ring when it has a line width.
struct Disc {
    let radius: CGFloat
    let color: UInt32
    var lineWidth: CGFloat?
}

/// The shapes of one variant of the icon, back to front.
struct Variant {
    let fileName: String
    let background: UInt32
    let discs: [Disc]
    let hands: [Stroke]
    var hub: Disc?
}

let canvas: CGFloat = 512
let pixels = 1024
let center = CGPoint(x: 256, y: 256)
let handWidth: CGFloat = 26
let minuteTip = CGPoint(x: 256, y: 132)
let monoMinuteTip = CGPoint(x: 256, y: 150)
let hourTip = CGPoint(x: 214, y: 329)

let variants = [
    Variant(
        fileName: "icon-light.png",
        background: 0xC6402A,
        discs: [Disc(radius: 176, color: 0xFBF6EF), Disc(radius: 126, color: 0xE6D9CA, lineWidth: 6)],
        hands: [Stroke(from: center, to: minuteTip, color: 0x2B201B), Stroke(from: center, to: hourTip, color: 0xC6402A)],
        hub: Disc(radius: 17, color: 0x2B201B)
    ),
    Variant(
        fileName: "icon-dark.png",
        background: 0x2A211C,
        discs: [Disc(radius: 176, color: 0xE8674F), Disc(radius: 126, color: 0xC6402A, lineWidth: 6)],
        hands: [Stroke(from: center, to: minuteTip, color: 0x1C1613), Stroke(from: center, to: hourTip, color: 0xFBF6EF)],
        hub: Disc(radius: 17, color: 0x1C1613)
    ),
    Variant(
        fileName: "icon-tinted.png",
        background: 0x2B201B,
        discs: [Disc(radius: 176, color: 0xFBF6EF, lineWidth: 22)],
        hands: [Stroke(from: center, to: monoMinuteTip, color: 0xFBF6EF), Stroke(from: center, to: hourTip, color: 0xFBF6EF)]
    ),
]

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

func draw(_ disc: Disc, in context: CGContext) {
    let box = CGRect(x: center.x - disc.radius, y: center.y - disc.radius, width: disc.radius * 2, height: disc.radius * 2)
    if let lineWidth = disc.lineWidth {
        context.setStrokeColor(color(disc.color))
        context.setLineWidth(lineWidth)
        context.strokeEllipse(in: box)
    } else {
        context.setFillColor(color(disc.color))
        context.fillEllipse(in: box)
    }
}

func draw(_ stroke: Stroke, in context: CGContext) {
    context.setStrokeColor(color(stroke.color))
    context.setLineWidth(handWidth)
    context.setLineCap(.round)
    context.move(to: stroke.from)
    context.addLine(to: stroke.to)
    context.strokePath()
}

func render(_ variant: Variant) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    let scale = CGFloat(pixels) / canvas
    context.translateBy(x: 0, y: CGFloat(pixels))
    context.scaleBy(x: scale, y: -scale)
    context.setFillColor(color(variant.background))
    context.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
    variant.discs.forEach { draw($0, in: context) }
    variant.hands.forEach { draw($0, in: context) }
    if let hub = variant.hub {
        draw(hub, in: context)
    }
    return context.makeImage()!
}

func write(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(url.path)")
    }
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconSet = root.appendingPathComponent("App/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)
for variant in variants {
    write(render(variant), to: iconSet.appendingPathComponent(variant.fileName))
    print("Wrote \(variant.fileName)")
}
