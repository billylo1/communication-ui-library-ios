//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCalling

enum CallCompositeCaptionsType: Int {
    case none
    case communication
    case teams
}
public enum CaptionsResultType {
    case final
    case partial
}

enum CallCompositeCaptionsErrors: Int {
    case none
    case captionsFailedToStart
    case captionsFailedToStop
    case captionsFailedToSetSpokenLanguage
    case captionsFailedToSetCaptionLanguage
}

/// Todo need to remove when Native SDK has the new error feature
enum CallCompositeCaptionsErrorsDescription: String {
    case captionsStartFailedCallNotConnected = "Get captions failed, call should be connected"
    case captionsStartFailedSpokenLanguageNotSupported = "The requested language is not supported"
    case captionsNotActive = " Captions are not active"
}

// changed to public
public struct CallCompositeCaptionsData: Identifiable, Equatable {
    /// to make CallCompositeCaptionsData to be identifiable
    public var id: Date { timestamp }       // changed

    public var resultType: CaptionsResultType
    public let speakerRawId: String
    public let speakerName: String
    public let spokenLanguage: String
    public let spokenText: String
    public let timestamp: Date
    public let captionLanguage: String?
    public let captionText: String?

    public static func == (lhs: CallCompositeCaptionsData, rhs: CallCompositeCaptionsData) -> Bool {        // changed
        // Define what makes two instances of CallCompositeCaptionsData equal
        return lhs.speakerRawId == rhs.speakerRawId &&
               lhs.resultType == rhs.resultType &&
               lhs.speakerName == rhs.speakerName &&
               lhs.spokenLanguage == rhs.spokenLanguage &&
               lhs.spokenText == rhs.spokenText &&
               lhs.captionLanguage == rhs.captionLanguage &&
               lhs.captionText == rhs.captionText
    }
}

extension AzureCommunicationCalling.TeamsCaptionsReceivedEventArgs {
    func toCallCompositeCaptionsData() -> CallCompositeCaptionsData {
        return CallCompositeCaptionsData(
            resultType: resultType.toCaptionsResultType(),
            speakerRawId: speaker.identifier.rawId,
            speakerName: speaker.displayName,
            spokenLanguage: spokenLanguage,
            spokenText: spokenText,
            timestamp: timestamp,
            captionLanguage: captionLanguage,
            captionText: captionText
        )
    }
}

 extension AzureCommunicationCalling.CommunicationCaptionsReceivedEventArgs {
    func toCallCompositeCaptionsData() -> CallCompositeCaptionsData {
        return CallCompositeCaptionsData(
            resultType: resultType.toCaptionsResultType(),
            speakerRawId: speaker.identifier.rawId,
            speakerName: speaker.displayName,
            spokenLanguage: spokenLanguage,
            spokenText: spokenText,
            timestamp: timestamp,
            captionLanguage: nil,
            captionText: nil
        )
    }
 }

extension AzureCommunicationCalling.CaptionsResultType {
    func toCaptionsResultType() -> CaptionsResultType {
        switch self {
        case .final:
            return .final
        case .partial:
            return .partial
        default:
            return .final
        }
    }
}

extension AzureCommunicationCalling.CaptionsType {
    func toCaptionsType() -> CallCompositeCaptionsType {
        switch self {
        case .teamsCaptions:
            return .teams
        case .communicationCaptions:
            return .communication
        default:
            return .none
        }
    }
}
