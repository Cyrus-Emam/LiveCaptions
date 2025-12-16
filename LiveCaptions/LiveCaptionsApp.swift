//
//  LiveCaptionsApp.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 11/30/25.
//

import SwiftUI

@main
struct LiveCaptionsApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
        }
    }
}
