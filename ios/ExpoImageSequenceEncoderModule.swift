// ios/ExpoImageSequenceEncoderModule.swift

import AVFoundation
import ExpoModulesCore
import UIKit

public class ExpoImageSequenceEncoderModule: Module {
  public func definition() -> ModuleDefinition {
    // Name for JS side
    Name("ExpoImageSequenceEncoder")

    // Example: Add constants if you want
    // Constants(["PI": Double.pi])

    // Async function that returns a Promise to JS
    AsyncFunction("encode") { (options: [String: Any]) -> String in
      let params = try EncoderParams(dict: options)

      NSLog("Encoding image sequence at \(params.folder) to \(params.output)")
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            try Self.runEncode(params: params)
            continuation.resume(returning: params.output)
          } catch {
            continuation.resume(throwing: error)
          }
        }
      }
    }

  }

  private struct EncoderParams {
    let folder: String
    let fps: Int32
    let width: Int
    let height: Int
    let output: String

    init(dict: [String: Any]) throws {
      guard
        let folder = dict["folder"] as? String,
        let fps = dict["fps"] as? NSNumber,
        let width = dict["width"] as? NSNumber,
        let height = dict["height"] as? NSNumber,
        let output = dict["output"] as? String
      else {
        throw NSError(
          domain: "ImageSeqEncoder", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Missing options"])
      }

      self.folder = folder.hasSuffix("/") ? folder : folder + "/"
      self.fps = fps.int32Value
      self.width = width.intValue
      self.height = height.intValue
      self.output = output
    }
  }

  private static func runEncode(params p: EncoderParams) throws {
    NSLog("🟢 [Encoder] params: \(p)")
    NSLog("🟢 [Encoder] p.folder: \(p.folder)")
    NSLog("🟢 [Encoder] p.fps: \(p.fps)")
    NSLog("🟢 [Encoder] p.width x height: \(p.width)x\(p.height)")
    NSLog("🟢 [Encoder] p.output: \(p.output)")

    // Clean any existing file at `output`
    try? FileManager.default.removeItem(atPath: p.output)

    // 1. Writer setup ---------------------------------------------------------
    let cleanOutputPath: String
    if p.output.hasPrefix("file://") {
      cleanOutputPath = String(p.output.dropFirst("file://".count))
    } else {
      cleanOutputPath = p.output
    }

    if FileManager.default.fileExists(atPath: cleanOutputPath) {
      NSLog("🟢 [Encoder] Output file already exists — deleting.")
      try? FileManager.default.removeItem(atPath: cleanOutputPath)
    } else {
      NSLog("🟢 [Encoder] No pre-existing output file.")
    }

    NSLog("🟢 [Encoder] Does output dir exist?")
    let outputDir = (cleanOutputPath as NSString).deletingLastPathComponent
    NSLog("🟢 [Encoder] outputDir: \(outputDir)")

    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: outputDir, isDirectory: &isDir) {
      NSLog("✅ [Encoder] Output dir exists: \(isDir.boolValue)")
    } else {
      NSLog("❌ [Encoder] Output dir does NOT exist")
    }

    let url = URL(fileURLWithPath: cleanOutputPath)

    NSLog("🟢 [Encoder] output URL: \(url.absoluteString)")
    NSLog("🟢 [Encoder] output path: \(url.path)")

    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)

    let profileLevel: String

    if #available(iOS 17.0, *) {
      profileLevel = "Main_AutoLevel"
    } else {
      profileLevel = "Main Profile Level 4.1"
    }
    NSLog("🟢 [Encoder] Writer created with profileLevel: \(profileLevel)")

    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: p.width,
      AVVideoHeightKey: p.height,
      // AVVideoCompressionPropertiesKey: [
      //   AVVideoAverageBitRateKey: 3_000_000,  // 3 Mbps
      //   AVVideoProfileLevelKey: profileLevel,
      // ],
    ]
    NSLog("🟢 [Encoder] Video outputSettings: \(settings)")

    // let input: AVAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    // Right way to do the above:
    let input = AVAssetWriterInput(
      mediaType: .video, outputSettings: settings, sourceFormatHint: nil)
    NSLog("🟢 [Encoder] Created AVAssetWriterInput")
    input.expectsMediaDataInRealTime = false
    if writer.canAdd(input) {
      NSLog("🟢 [Encoder] Adding input to writer")
      writer.add(input)
      NSLog("🟢 [Encoder] Added writer input")
    } else {
      NSLog("❌ [Encoder] Cannot add AVAssetWriterInput")
      throw NSError(
        domain: "ImageSeqEncoder",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "Cannot add AVAssetWriterInput"])
    }

    let attributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: p.width,
      kCVPixelBufferHeightKey as String: p.height,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:],  // Always needed
      kCVPixelBufferOpenGLCompatibilityKey as String: true,  // Helps on older devices
      kCVPixelBufferMetalCompatibilityKey as String: true,  // Helps on modern devices
    ]
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: attributes)

    NSLog("🟢 [Encoder] PixelBufferAdaptor created: \(adaptor)")
    NSLog("🟢 [Encoder] PixelBufferAdaptor pool: \(String(describing: adaptor.pixelBufferPool))")

    guard writer.startWriting() else { throw writer.error! }
    writer.startSession(atSourceTime: .zero)

    guard let pxBufPool = adaptor.pixelBufferPool else {
      NSLog("❌ [Encoder] Pixel buffer pool is nil")
      throw NSError(
        domain: "ImageSeqEncoder",
        code: 7,
        userInfo: [NSLocalizedDescriptionKey: "Pixel buffer pool creation failed"])
    }
    NSLog("✅ [Encoder] PixelBufferPool created: \(pxBufPool)")

    // 2. Enumerate PNG frames -------------------------------------------------
    let fileNames = try FileManager.default
      .contentsOfDirectory(atPath: p.folder)
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    guard !fileNames.isEmpty else {
      throw NSError(
        domain: "ImageSeqEncoder",
        code: 6,
        userInfo: [NSLocalizedDescriptionKey: "No PNG frames found in folder"])
    }

    NSLog("🟢 [Encoder] Found \(fileNames.count) files:")
    fileNames.forEach { NSLog("  - \($0)") }

    var frameIdx: Int64 = 0
    let frameDuration = CMTime(value: 1, timescale: p.fps)

    for name in fileNames where name.hasSuffix(".png") {
      try autoreleasepool {
        let path = p.folder + name
        NSLog("🟢 [Encoder] Processing frame: \(path)")
        guard let uiImg = UIImage(contentsOfFile: path),
          let cgImg = uiImg.cgImage
        else {
          throw NSError(
            domain: "ImageSeqEncoder",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load frame at \(path)"])
        }

        guard let pxBufPool = adaptor.pixelBufferPool else {
          throw NSError(
            domain: "ImageSeqEncoder",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Pixel buffer pool is nil"])
        }

        var pixelBufferOut: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pxBufPool, &pixelBufferOut)
        guard let pixelBuffer = pixelBufferOut else {
          NSLog("❌ [Encoder] Failed to create pixel buffer at frame \(frameIdx)")
          throw NSError(
            domain: "ImageSeqEncoder",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "Could not create pixel buffer"])
        }

        // Draw UIImage into pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let ctx = CGContext(
          data: CVPixelBufferGetBaseAddress(pixelBuffer),
          width: p.width,
          height: p.height,
          bitsPerComponent: 8,
          bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue
        )
        ctx?.draw(cgImg, in: CGRect(x: 0, y: 0, width: p.width, height: p.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIdx))
        while !input.isReadyForMoreMediaData { usleep(2_000) }

        NSLog(
          "🟢 [Encoder] Appended frame \(frameIdx) at time: \(CMTimeGetSeconds(presentationTime)) s")

        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        frameIdx += 1
      }
    }

    // 3. Finish ---------------------------------------------------------------
    NSLog("🟢 [Encoder] Marking input as finished")
    input.markAsFinished()

    // Wait for finishWriting to complete
    let finishGroup = DispatchGroup()
    finishGroup.enter()
    writer.finishWriting {
      finishGroup.leave()
    }
    finishGroup.wait()

    NSLog("✅ [Encoder] Writer finished with status: \(writer.status.rawValue)")
    NSLog("✅ [Encoder] Encoding complete: \(p.output)")

    if writer.status != .completed {
      throw writer.error
        ?? NSError(
          domain: "ImageSeqEncoder", code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Unknown writer error"])
    }

  }
}
