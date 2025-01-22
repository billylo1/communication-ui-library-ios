//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

// display an alert
import UIKit

class AlertUtil {
    
    static func sendNotification(title: String, body: String) {
        // send localnotification
        let uuidString = UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)


        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.add(request)
        print("Notification sent")

    }
}
