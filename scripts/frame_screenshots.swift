#!/usr/bin/env swift
// =============================================================================
// frame_screenshots.swift
// Turns raw screenshots into App Store marketing images: headline + subline on
// top, rounded screenshot below. Output keeps the input pixel size, no alpha.
//
// Usage:
//   swift scripts/frame_screenshots.swift <raw_dir> <out_dir> <en|es>
//
// Edit `shots` below to change order, captions or colors. Missing inputs are skipped.
// =============================================================================

import AppKit

struct Shot {
    let file: String          // raw screenshot name (without .png)
    let accent: NSColor
    let background: NSColor
    let en: (String, String)  // (headline, subline)
    let es: (String, String)
}

func hex(_ v: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

let shots: [Shot] = [
    Shot(file: "03_gameplay_neon", accent: hex(0x22D3EE), background: hex(0x05060A),
         en: ("Find the NEWEST dot", "One wrong tap and it's game over"),
         es: ("Encuentra el punto NUEVO", "Un toque equivocado y pierdes")),
    Shot(file: "03_gameplay_forest", accent: hex(0x4ADE80), background: hex(0x050D07),
         en: ("How far can your\nmemory go?", "Every round adds one more"),
         es: ("¿Hasta dónde llega\ntu memoria?", "Cada ronda suma uno más")),
    Shot(file: "04_arcade_gameplay", accent: hex(0xA78BFA), background: hex(0x080510),
         en: ("Beat the clock", "Arcade mode gets faster every level"),
         es: ("Vence al reloj", "El modo Arcade acelera en cada nivel")),
    Shot(file: "03_gameplay_ocean", accent: hex(0xF472B6), background: hex(0x03080F),
         en: ("Owls, aliens,\njellyfish & more", "Every theme has its own dots"),
         es: ("Búhos, aliens,\nmedusas y más", "Cada tema tiene sus propios puntos")),
    Shot(file: "05_themes", accent: hex(0xFACC15), background: hex(0x080510),
         en: ("Unlock 8 themes", "Free and premium worlds to explore"),
         es: ("Desbloquea 8 temas", "Mundos gratis y premium por descubrir")),
    Shot(file: "03_gameplay_doctorping", accent: hex(0x64B5D9), background: hex(0x05101A),
         en: ("Train your brain", "Quick rounds, anytime, anywhere"),
         es: ("Entrena tu mente", "Partidas rápidas, cuando quieras")),
]

let args = CommandLine.arguments
guard args.count == 4, ["en", "es"].contains(args[3]) else {
    print("usage: swift frame_screenshots.swift <raw_dir> <out_dir> <en|es>"); exit(1)
}
let rawDir = URL(fileURLWithPath: args[1]), outDir = URL(fileURLWithPath: args[2]), locale = args[3]
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    return base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
}

func drawCentered(_ text: String, font: NSFont, color: NSColor, top: CGFloat, width: CGFloat, height: CGFloat) -> CGFloat {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineHeightMultiple = 0.95
    let shadow = NSShadow()
    shadow.shadowColor = color.withAlphaComponent(0.45)
    shadow.shadowBlurRadius = font.pointSize * 0.25
    let str = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color,
                                                            .paragraphStyle: para, .shadow: shadow])
    let box = str.boundingRect(with: NSSize(width: width * 0.88, height: .greatestFiniteMagnitude),
                               options: [.usesLineFragmentOrigin, .usesFontLeading])
    // AppKit origin is bottom-left; convert from top-based layout
    str.draw(with: NSRect(x: width * 0.06, y: height - top - box.height, width: width * 0.88, height: box.height),
             options: [.usesLineFragmentOrigin, .usesFontLeading])
    return top + box.height
}

var index = 0
for shot in shots {
    let src = rawDir.appendingPathComponent(shot.file + ".png")
    guard let raw = NSImage(contentsOf: src),
          let rawCG = raw.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("  skip (missing): \(shot.file)"); continue
    }
    index += 1
    let w = CGFloat(rawCG.width), h = CGFloat(rawCG.height)
    let ctx = CGContext(data: nil, width: rawCG.width, height: rawCG.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

    // Background: theme color with a soft accent glow behind the phone
    shot.background.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()
    let glow = NSGradient(colors: [shot.accent.withAlphaComponent(0.28), shot.accent.withAlphaComponent(0)])!
    glow.draw(fromCenter: NSPoint(x: w / 2, y: h * 0.45), radius: 0,
              toCenter: NSPoint(x: w / 2, y: h * 0.45), radius: w * 0.9, options: [])

    // Captions
    let (headline, subline) = locale == "es" ? shot.es : shot.en
    var y = h * 0.055
    y = drawCentered(headline, font: roundedFont(w * 0.088, .black), color: .white, top: y, width: w, height: h)
    y += h * 0.012
    y = drawCentered(subline, font: roundedFont(w * 0.045, .semibold), color: shot.accent, top: y, width: w, height: h)

    // Screenshot: scaled, rounded, bleeding off the bottom edge
    let scale: CGFloat = 0.80
    let sw = w * scale, sh = h * scale
    let phoneTop = max(y + h * 0.035, h * 0.22)
    let rect = NSRect(x: (w - sw) / 2, y: h - phoneTop - sh, width: sw, height: sh)
    // iPad status bar sits closer to the corners, so it gets a tighter radius
    let radius = sh * (h / w > 1.8 ? 0.05 : 0.02)
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.saveGraphicsState()
    let phoneShadow = NSShadow()
    phoneShadow.shadowColor = shot.accent.withAlphaComponent(0.55)
    phoneShadow.shadowBlurRadius = w * 0.05
    phoneShadow.set()
    shot.background.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    ctx.draw(rawCG, in: rect)
    NSGraphicsContext.restoreGraphicsState()
    shot.accent.withAlphaComponent(0.6).setStroke()
    path.lineWidth = w * 0.006
    path.stroke()

    let out = outDir.appendingPathComponent(String(format: "%02d_%@.png", index, shot.file))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try rep.representation(using: .png, properties: [:])!.write(to: out)
    print("  ✓ \(out.lastPathComponent)")
}
