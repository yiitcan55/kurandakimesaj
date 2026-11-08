import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VideoSpeechChannel") {
      VideoSpeechChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Videodan Meal (iOS): videonun sesini CİHAZIN konuşma tanıyıcısıyla metne
/// çevirir; video uygulamadan yüklenmez. Android karşılığı VideoSpeechChannel.kt.
/// Ses AVAssetReader ile 16 kHz mono'ya çevrilir, ~50 sn'lik parçalar (kesim en
/// sessiz 100 ms'de) SFSpeechRecognizer'a verilir. Kelime düzeyinde zaman döner;
/// bölümlere ayırma Dart'ta (wordsToSegments). Şartname:
/// docs/superpowers/specs/2026-11-08-iphone-videodan-ayet-design.md
final class VideoSpeechChannel {
  private static var instance: VideoSpeechChannel?
  private let channel: FlutterMethodChannel
  private var session: VideoSpeechSession?

  static func register(messenger: FlutterBinaryMessenger) {
    instance = VideoSpeechChannel(messenger: messenger)
  }

  private init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "kurandakimesaj/video_speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))?.isAvailable == true)
    case "requestPermission":
      SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async { result(status == .authorized) }
      }
    case "transcribe":
      transcribe(call.arguments as? [String: Any], result)
    case "cancel":
      session?.cancel()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(_ args: [String: Any]?, _ result: @escaping FlutterResult) {
    if session != nil {
      result(FlutterError(code: "speech_busy", message: "Başka bir tanıma sürüyor", details: nil))
      return
    }
    guard let path = args?["path"] as? String, FileManager.default.isReadableFile(atPath: path) else {
      result(FlutterError(code: "speech_no_audio", message: "Video okunamadı", details: nil))
      return
    }
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
      result(FlutterError(code: "speech_permission", message: "Konuşma tanıma izni yok", details: nil))
      return
    }
    let locale = args?["locale"] as? String ?? "ar-SA"
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)), recognizer.isAvailable else {
      result(FlutterError(code: "speech_language", message: "Tanıyıcı bu dili desteklemiyor", details: nil))
      return
    }
    let s = VideoSpeechSession(url: URL(fileURLWithPath: path), recognizer: recognizer) { [weak self] outcome in
      self?.session = nil
      switch outcome {
      case .success(let words): result(words)
      case .failure(let f): result(FlutterError(code: f.code, message: f.message, details: nil))
      }
    }
    session = s
    s.start()
  }
}

struct VideoSpeechFailure: Error {
  let code: String
  let message: String
}

/// Tek tanıma oturumu. Sonuç yalnız BİR kez döner; tanıyıcı işleri ana iş
/// parçacığında, ses okuma arka planda.
final class VideoSpeechSession {
  static let rate = 16000.0
  private let url: URL
  private let recognizer: SFSpeechRecognizer
  private let completion: (Result<[[String: Any]], VideoSpeechFailure>) -> Void
  private var useOnDevice: Bool
  private var task: SFSpeechRecognitionTask?
  private var timeout: DispatchWorkItem?
  private var words: [[String: Any]] = []
  private var finished = false

  init(url: URL, recognizer: SFSpeechRecognizer,
       completion: @escaping (Result<[[String: Any]], VideoSpeechFailure>) -> Void) {
    self.url = url
    self.recognizer = recognizer
    self.completion = completion
    self.useOnDevice = recognizer.supportsOnDeviceRecognition
  }

  func start() {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let pcm = try VideoSpeechSession.readPCM(self.url)
        let ranges = VideoSpeechSession.chunkRanges(count: pcm.count, pcm: pcm)
        DispatchQueue.main.async { self.run(pcm, ranges, 0, retried: false) }
      } catch let f as VideoSpeechFailure {
        DispatchQueue.main.async { self.finish(.failure(f)) }
      } catch {
        DispatchQueue.main.async {
          self.finish(.failure(VideoSpeechFailure(code: "speech_no_audio", message: error.localizedDescription)))
        }
      }
    }
  }

  func cancel() {
    task?.cancel()
    finish(.failure(VideoSpeechFailure(code: "speech_unavailable", message: "iptal edildi")))
  }

  private func finish(_ outcome: Result<[[String: Any]], VideoSpeechFailure>) {
    if finished { return }
    finished = true
    timeout?.cancel()
    task = nil
    completion(outcome)
  }

  /// Video → 16 kHz mono 16-bit PCM (AVAssetReader dönüştürür).
  static func readPCM(_ url: URL) throws -> [Int16] {
    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first else {
      throw VideoSpeechFailure(code: "speech_no_audio", message: "Videoda ses izi yok")
    }
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: rate,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ])
    reader.add(output)
    guard reader.startReading() else {
      throw VideoSpeechFailure(code: "speech_no_audio", message: reader.error?.localizedDescription ?? "Ses okunamadı")
    }
    var pcm: [Int16] = []
    while let sample = output.copyNextSampleBuffer() {
      guard let block = CMSampleBufferGetDataBuffer(sample) else { continue }
      let length = CMBlockBufferGetDataLength(block)
      if length < 2 { continue }
      var chunk = [Int16](repeating: 0, count: length / 2)
      chunk.withUnsafeMutableBytes { raw in
        _ = CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: (length / 2) * 2, destination: raw.baseAddress!)
      }
      pcm.append(contentsOf: chunk)
    }
    if reader.status == .failed {
      throw VideoSpeechFailure(code: "speech_no_audio", message: reader.error?.localizedDescription ?? "Ses okunamadı")
    }
    if pcm.isEmpty {
      throw VideoSpeechFailure(code: "speech_no_audio", message: "Ses izi boş")
    }
    return pcm
  }

  /// ~50 sn'lik parçalar; kesim 45–55 sn arasındaki en sessiz 100 ms'nin ortası.
  static func chunkRanges(count: Int, pcm: [Int16]) -> [Range<Int>] {
    let r = Int(rate)
    let lo = 45 * r, hi = 55 * r, win = r / 10
    var ranges: [Range<Int>] = []
    var start = 0
    while count - start > hi {
      var bestCut = start + 50 * r
      var bestEnergy = Int64.max
      var w = start + lo
      while w + win <= start + hi {
        var e: Int64 = 0
        for i in w..<(w + win) {
          let v = Int64(pcm[i])
          e += v * v
        }
        if e < bestEnergy {
          bestEnergy = e
          bestCut = w + win / 2
        }
        w += win
      }
      ranges.append(start..<bestCut)
      start = bestCut
    }
    ranges.append(start..<count)
    return ranges
  }

  private func run(_ pcm: [Int16], _ ranges: [Range<Int>], _ index: Int, retried: Bool) {
    if finished { return }
    if index >= ranges.count {
      finish(.success(words))
      return
    }
    let range = ranges[index]
    let offset = Double(range.lowerBound) / VideoSpeechSession.rate
    guard let format = AVAudioFormat(standardFormatWithSampleRate: VideoSpeechSession.rate, channels: 1) else {
      finish(.failure(VideoSpeechFailure(code: "speech_unavailable", message: "Ses biçimi kurulamadı")))
      return
    }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = false
    request.taskHint = .dictation
    request.requiresOnDeviceRecognition = useOnDevice
    if #available(iOS 16.0, *) {
      request.addsPunctuation = false
    }

    var handled = false
    let resume: (Error?, SFSpeechRecognitionResult?) -> Void = { [weak self] error, result in
      guard let self = self, !self.finished, !handled else { return }
      if let result = result, !result.isFinal, error == nil { return }
      handled = true
      self.timeout?.cancel()
      if let result = result, result.isFinal {
        for seg in result.bestTranscription.segments {
          let start = offset + seg.timestamp
          self.words.append(["text": seg.substring, "start": start, "end": start + seg.duration])
        }
        self.run(pcm, ranges, index + 1, retried: false)
        return
      }
      let ns = (error ?? NSError(domain: "VideoSpeech", code: -1)) as NSError
      // "Konuşma algılanmadı" (kAFAssistantErrorDomain 1110; sunucu modunda bazen
      // 203 "Retry"): boş parça, hata değil — o parçadan kelime gelmez.
      if ns.domain == "kAFAssistantErrorDomain" && (ns.code == 1110 || ns.code == 203) {
        self.run(pcm, ranges, index + 1, retried: false)
        return
      }
      // Cihaz üstü model yok/inmedi: aynı parçayı bir kez sunucu moduyla dene.
      if self.useOnDevice && !retried {
        self.useOnDevice = false
        self.run(pcm, ranges, index, retried: true)
        return
      }
      let code = ns.domain == NSURLErrorDomain ? "speech_network" : "speech_unavailable"
      self.finish(.failure(VideoSpeechFailure(code: code, message: "\(ns.domain) \(ns.code): \(ns.localizedDescription)")))
    }

    task = recognizer.recognitionTask(with: request) { result, error in
      DispatchQueue.main.async { resume(error, result) }
    }

    var i = range.lowerBound
    let step = Int(VideoSpeechSession.rate)
    while i < range.upperBound {
      let n = min(step, range.upperBound - i)
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(n)),
            let dst = buffer.floatChannelData?[0] else { break }
      buffer.frameLength = AVAudioFrameCount(n)
      for k in 0..<n {
        dst[k] = Float(pcm[i + k]) / 32768.0
      }
      request.append(buffer)
      i += n
    }
    request.endAudio()

    let work = DispatchWorkItem { [weak self] in
      guard let self = self, !self.finished, !handled else { return }
      handled = true
      self.task?.cancel()
      self.finish(.failure(VideoSpeechFailure(code: "speech_unavailable", message: "Tanıyıcı 60 sn yanıt vermedi")))
    }
    timeout = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: work)
  }
}
