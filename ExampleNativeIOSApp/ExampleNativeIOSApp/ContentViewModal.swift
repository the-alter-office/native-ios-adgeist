//
//  ContentViewModal.swift
//  ExampleNativeIOSApp
//
//  Created by kishore on 02/05/25.
//

import Foundation
import AdgeistKit

final class ContentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var activityDescription = "Tap 👇 to generate an activity"
    
    func generateActivity() {
        let creative = AdgeistCore.shared.getCreative()
        
        creative.fetchCreative(adSpaceId: "67c99c7a34929568f405e7ff", publisherId: "67a056c63205fce2290d1cda") { creativeData in
            print("success----------: \(creativeData)")
        }
    }
}
