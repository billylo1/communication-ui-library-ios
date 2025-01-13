import AzureCommunicationCalling

import AVFoundation

protocol SamplesProducer {
    func produceSample(_ currentSample: Int,
                           options: RawOutgoingAudioStreamOptions) -> AVAudioPCMBuffer
}

    // Let's use a simple Tone data producer as example.
    // Producing PCM buffers.

final class RawOutgoingAudioSender {
    let stream: RawOutgoingAudioStream
    let options: RawOutgoingAudioStreamOptions
    let producer: SamplesProducer

    private var timer: Timer?
    private var currentSample: Int = 0
    private var currentTimestamp: Int64 = 0

    init(stream: RawOutgoingAudioStream,
         options: RawOutgoingAudioStreamOptions,
         producer: SamplesProducer) {
        
        print("RawOutgoingAudioSender()")
        self.stream = stream
        self.options = options
        self.producer = producer
    }

    func start() {
        
        print("RawOutgoingAudioSender::start()")

        let properties = self.options.properties
        let interval = properties.bufferDuration.timeInterval

        let channelCount = AVAudioChannelCount(properties.channelMode.channelCount)
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                   sampleRate: Double(properties.sampleRate.valueInHz),
                                   channels: channelCount,
                                   interleaved: channelCount > 1)!
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let sample = self.producer.produceSample(self.currentSample, options: self.options)
            let rawBuffer = RawAudioBuffer()
            rawBuffer.buffer = sample
            rawBuffer.timestampInTicks = self.currentTimestamp
            self.stream.send(buffer: rawBuffer, completionHandler: { error in
                if let error = error {
                    // Handle possible error.
                    print(error)
                }
            })

            self.currentTimestamp += Int64(properties.bufferDuration.value)
            self.currentSample += 1
        }
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }

    deinit {
        stop()
    }
}

class ToneSampleProducer: NSObject, SamplesProducer {
    func produceSample(_ currentSample: Int, options: RawOutgoingAudioStreamOptions) -> AVAudioPCMBuffer {
        let sampleRate = options.properties.sampleRate
        let channelMode = options.properties.channelMode
        let bufferDuration = options.properties.bufferDuration
        let numberOfChunks = UInt32(1000 / bufferDuration.value)
        let bufferFrameSize = UInt32(sampleRate.valueInHz) / numberOfChunks
        let frequency = 400
        
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: Double(sampleRate.valueInHz),
                                         channels: channelMode.channelCount,
                                         interleaved: channelMode == .stereo) else {
            fatalError("Failed to create PCM Format")
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferFrameSize) else {
            fatalError("Failed to create PCM buffer")
        }
        
        buffer.frameLength = bufferFrameSize
        
        let factor: Double = ((2 as Double) * Double.pi) / (Double(sampleRate.valueInHz)/Double(frequency))
        var interval = 0
        for sampleIdx in 0..<Int(buffer.frameCapacity * channelMode.channelCount) {
            let sample = sin(factor * Double(currentSample + interval))
            // Scale to maximum amplitude. Int16.max is 37,767.
            let value = Int16(sample * Double(Int16.max))
            
            guard let underlyingByteBuffer = buffer.mutableAudioBufferList.pointee.mBuffers.mData else {
                continue
            }
            underlyingByteBuffer.assumingMemoryBound(to: Int16.self).advanced(by: sampleIdx).pointee = value
            interval += channelMode == .mono ? 2 : 1
        }
        
        return buffer
        
    }
}


class DelegateImplementer: NSObject, RawOutgoingAudioStreamDelegate {
    
    public var rawOutgoingAudioSender: RawOutgoingAudioSender?
    
    func rawOutgoingAudioStream(_ rawOutgoingAudioStream: RawOutgoingAudioStream,
                                didChangeState args: AudioStreamStateChangedEventArgs) {
        if args.stream.state == AudioStreamState.started {
            print("ACSAudioStreamState.started")
            rawOutgoingAudioSender?.start()
        } else if args.stream.state == AudioStreamState.stopped {
            print("ACSAudioStreamState.stopped")
            rawOutgoingAudioSender?.stop()
        }
    }
    
}

