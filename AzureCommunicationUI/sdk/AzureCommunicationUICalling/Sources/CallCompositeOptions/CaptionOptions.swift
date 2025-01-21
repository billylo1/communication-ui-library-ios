//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//
import Foundation

/// Configuration options for captions in a UI component.
public struct CaptionsOptions {
    let captionsOn: Bool
    let spokenLanguage: String?
    let captionLanguage: String?

    public init(captionsOn: Bool = true, spokenLanguage: String? = nil, captionLanguage: String? = nil) {
        self.spokenLanguage = spokenLanguage
        self.captionsOn = captionsOn
        self.captionLanguage = captionLanguage
    }
}
