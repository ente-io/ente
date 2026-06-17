import AVFoundation
import Flutter
import UIKit

private struct EnteQrScannerOverlay {
  let cutOutSize: CGFloat

  static func from(_ args: Any?) -> EnteQrScannerOverlay {
    guard let map = args as? [String: Any] else {
      return EnteQrScannerOverlay(cutOutSize: 260)
    }
    let cutOutSize = (map["cutOutSize"] as? NSNumber)?.doubleValue ?? 260
    return EnteQrScannerOverlay(cutOutSize: CGFloat(cutOutSize))
  }
}

private final class EnteQrScannerPreviewView: UIView {
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

final class EnteQrScannerView: NSObject, FlutterPlatformView, AVCaptureMetadataOutputObjectsDelegate {
  private static let scanPadding: CGFloat = 48

  private let containerView: EnteQrScannerPreviewView
  private let channel: FlutterMethodChannel
  private let overlay: EnteQrScannerOverlay
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "io.ente.qr_scanner.session")
  private let metadataQueue = DispatchQueue(label: "io.ente.qr_scanner.metadata")
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var metadataOutput: AVCaptureMetadataOutput?
  private var captureDevice: AVCaptureDevice?
  private var isConfigured = false
  private var isPaused = false
  private var isDisposed = false
  private var lastEmittedText: String?
  private var lastEmittedAt = Date.distantPast

  init(
    frame: CGRect,
    viewId: Int64,
    args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    overlay = EnteQrScannerOverlay.from(args)
    containerView = EnteQrScannerPreviewView(frame: frame)
    channel = FlutterMethodChannel(
      name: "io.ente.qr_scanner/view_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    containerView.backgroundColor = .black
    containerView.onLayout = { [weak self] in
      self?.updatePreviewLayout()
    }
    channel.setMethodCallHandler(handle)
    requestPermissionAndStart()
  }

  func view() -> UIView {
    containerView
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pause":
      pause()
      result(nil)
    case "resume":
      resume()
      result(nil)
    case "getTorchStatus":
      result(torchStatus())
    case "toggleTorch":
      toggleTorch(result: result)
    case "dispose":
      result(nil)
      dispose()
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermissionAndStart() {
    #if targetEnvironment(simulator)
      return
    #else
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        configureAndStart()
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
          if granted {
            self?.configureAndStart()
          } else {
            self?.emitError("Camera permission denied")
          }
        }
      default:
        emitError("Camera permission denied")
      }
    #endif
  }

  private func configureAndStart() {
    sessionQueue.async { [weak self] in
      guard let self = self, !self.isDisposed else {
        return
      }
      if !self.isConfigured {
        self.configureSession()
      }
      if !self.isPaused && !self.session.isRunning {
        self.session.startRunning()
      }
    }
  }

  private func configureSession() {
    session.beginConfiguration()
    session.sessionPreset = .high

    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input)
    else {
      session.commitConfiguration()
      emitError("Back camera is unavailable")
      return
    }
    session.addInput(input)
    captureDevice = device

    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else {
      session.commitConfiguration()
      emitError("QR metadata output is unavailable")
      return
    }
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: metadataQueue)
    if output.availableMetadataObjectTypes.contains(.qr) {
      output.metadataObjectTypes = [.qr]
    }
    metadataOutput = output

    session.commitConfiguration()
    isConfigured = true
    configureFocusAndExposure(device)
    emitTorchStatus()

    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.previewLayer == nil else {
        return
      }
      let layer = AVCaptureVideoPreviewLayer(session: self.session)
      layer.videoGravity = .resizeAspectFill
      self.previewLayer = layer
      self.containerView.layer.insertSublayer(layer, at: 0)
      self.updatePreviewLayout()
    }
  }

  private func configureFocusAndExposure(_ device: AVCaptureDevice) {
    do {
      try device.lockForConfiguration()
      let centerPoint = CGPoint(x: 0.5, y: 0.5)
      if device.isFocusPointOfInterestSupported {
        device.focusPointOfInterest = centerPoint
      }
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
      if device.isExposurePointOfInterestSupported {
        device.exposurePointOfInterest = centerPoint
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
      device.unlockForConfiguration()
    } catch {
      emitError("Failed to configure camera focus")
    }
  }

  private func updatePreviewLayout() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in
        self?.updatePreviewLayout()
      }
      return
    }

    previewLayer?.frame = containerView.bounds
    guard
      let previewLayer = previewLayer,
      let metadataOutput = metadataOutput,
      !containerView.bounds.isEmpty
    else {
      return
    }
    metadataOutput.rectOfInterest = previewLayer.metadataOutputRectConverted(
      fromLayerRect: scanRect(in: containerView.bounds)
    )
  }

  private func scanRect(in bounds: CGRect) -> CGRect {
    let maxSide = min(bounds.width, bounds.height)
    let side = min(
      overlay.cutOutSize + Self.scanPadding * 2,
      maxSide
    )
    return CGRect(
      x: bounds.midX - side / 2,
      y: bounds.midY - side / 2,
      width: side,
      height: side
    )
  }

  private func pause() {
    isPaused = true
    sessionQueue.async { [weak self] in
      guard let self = self, self.session.isRunning else {
        return
      }
      self.session.stopRunning()
    }
  }

  private func resume() {
    guard !isDisposed else {
      return
    }
    isPaused = false
    configureAndStart()
  }

  private func torchStatus() -> Bool? {
    guard let device = captureDevice, device.hasTorch else {
      return nil
    }
    return device.torchMode == .on
  }

  private func toggleTorch(result: @escaping FlutterResult) {
    guard let device = captureDevice, device.hasTorch else {
      result(nil)
      return
    }
    do {
      try device.lockForConfiguration()
      device.torchMode = device.torchMode == .on ? .off : .on
      device.unlockForConfiguration()
      emitTorchStatus()
      result(nil)
    } catch {
      result(FlutterError(
        code: "torch_error",
        message: "Failed to toggle torch",
        details: nil
      ))
    }
  }

  private func dispose() {
    guard !isDisposed else {
      return
    }
    isDisposed = true
    channel.setMethodCallHandler(nil)
    sessionQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      if self.session.isRunning {
        self.session.stopRunning()
      }
      self.session.inputs.forEach { self.session.removeInput($0) }
      self.session.outputs.forEach { self.session.removeOutput($0) }
    }
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard
      !isDisposed,
      !isPaused,
      let readableObject = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
      readableObject.type == .qr,
      let payload = readableObject.stringValue,
      !payload.isEmpty
    else {
      return
    }
    emitCode(payload)
  }

  private func emitCode(_ text: String) {
    let now = Date()
    if lastEmittedText == text && now.timeIntervalSince(lastEmittedAt) < 1.5 {
      return
    }
    lastEmittedText = text
    lastEmittedAt = now
    DispatchQueue.main.async { [weak self] in
      guard let self = self, !self.isDisposed, !self.isPaused else {
        return
      }
      self.channel.invokeMethod("onCode", arguments: text)
    }
  }

  private func emitError(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, !self.isDisposed else {
        return
      }
      self.channel.invokeMethod("onError", arguments: message)
    }
  }

  private func emitTorchStatus() {
    let status = torchStatus()
    DispatchQueue.main.async { [weak self] in
      guard let self = self, !self.isDisposed else {
        return
      }
      self.channel.invokeMethod("onTorchStatusChanged", arguments: status)
    }
  }
}
