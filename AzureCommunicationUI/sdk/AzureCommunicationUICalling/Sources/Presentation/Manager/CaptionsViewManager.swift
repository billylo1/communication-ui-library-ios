//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//
import AzureCommunicationCommon
import AzureCommunicationCalling


import UIKit
import Combine
import SwiftUI

class CaptionsViewManager: ObservableObject {
    var isTranslationEnabled = false
    private let callingSDKWrapper: CallingSDKWrapperProtocol
    private let store: Store<AppState, Action>
    private let eventsHandler: CallComposite.Events
    @Published var captionData = [CallCompositeCaptionsData]()
    private var subscriptions = Set<AnyCancellable>()
    private let maxCaptionsCount = 50
    private let finalizationDelay: TimeInterval = 5 // seconds

    init(store: Store<AppState, Action>, callingSDKWrapper: CallingSDKWrapperProtocol, callCompositeEventsHandler: CallComposite.Events) {
        self.callingSDKWrapper = callingSDKWrapper
        self.store = store
        self.eventsHandler = callCompositeEventsHandler
        subscribeToCaptions()
    }

    private func subscribeToCaptions() {
        callingSDKWrapper.callingEventsHandler.captionsReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newData in
                self?.handleNewData(newData)
            }
            .store(in: &subscriptions)
        store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.receive(state: state)
            }.store(in: &subscriptions)
    }

    private func receive(state: AppState) {
        print("captionLanguage = \(state.captionsState.captionLanguage ?? "no caption language")")
        isTranslationEnabled = state.captionsState.captionLanguage?.isEmpty == false
    }

    func handleNewData(_ newData: CallCompositeCaptionsData) {
//        if !shouldAddCaption(newData) {
//            return
//        }
//
        self.processNewCaption(newCaption: newData)
    }

    private var lastTranslation: Date?
    private func processNewCaption(newCaption: CallCompositeCaptionsData) {
        Task {
            var translatedCaption: CallCompositeCaptionsData = newCaption
            let shouldTranslate = (lastTranslation == nil || newCaption.resultType == .final || Date().timeIntervalSince(lastTranslation!) > 2)
            if shouldTranslate {
                let translatedText = await TranslatorUtil.translate(inputText: newCaption.spokenText, fromLocale: newCaption.spokenLanguage, toLocale: self.eventsHandler.captionLanguage ?? "ja-JP")
                if !translatedText.isEmpty {
                    print(translatedText)
                    translatedCaption = CallCompositeCaptionsData(
                        resultType: newCaption.resultType,
                        speakerRawId: newCaption.speakerRawId,
                        speakerName: newCaption.speakerName,
                        spokenLanguage: newCaption.spokenLanguage,
                        spokenText: newCaption.spokenText,
                        timestamp: newCaption.timestamp,
                        captionLanguage: self.eventsHandler.captionLanguage,
                        captionText: translatedText
                    )
                    lastTranslation = Date()
                }
                print(translatedCaption)
            }


            guard !captionData.isEmpty else {
                captionData.append(translatedCaption)
                return
            }

            let lastIndex = captionData.count - 1
            var lastCaption = captionData[lastIndex]



            if lastCaption.resultType == .final {
                guard let onCaptionsReceived = eventsHandler.onCaptionsReceived else {
                    return
                }
                
                captionData.append(translatedCaption)
                onCaptionsReceived(translatedCaption)


            } else if lastCaption.speakerRawId == newCaption.speakerRawId {
                // Update the last caption if it's not finalized and from the same speaker
                if shouldTranslate && translatedCaption.captionText != nil {
                    captionData[lastIndex] = translatedCaption
                }
            } else {

                if shouldFinalizeLastCaption(lastCaption: lastCaption, newCaption: translatedCaption) {
                    lastCaption.resultType = .final
                    captionData[lastIndex] = lastCaption // Commit the finalization change
                    captionData.append(translatedCaption)
                }
            }

            DispatchQueue.main.async {
                
                if self.captionData.count > self.maxCaptionsCount {
                    withAnimation {
                        _ = self.captionData.removeFirst()
                    }
                }
            }

        }
        
        
    }

    // Decide if a new caption should be added to the list
    private func shouldAddCaption(_ caption: CallCompositeCaptionsData) -> Bool {
//        if isTranslationEnabled {
            // Only add caption if translation is enabled and caption text is not empty
            return !(caption.captionText?.isEmpty ?? true)
//        }
        // Always add caption if translation is not enabled
//        return true
    }

    private func shouldFinalizeLastCaption(lastCaption: CallCompositeCaptionsData,
                                           newCaption: CallCompositeCaptionsData) -> Bool {
        let duration = newCaption.timestamp.timeIntervalSince(lastCaption.timestamp)
        return duration > finalizationDelay
    }
}
