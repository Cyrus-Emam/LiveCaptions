//
//  LiveCaptionsApp.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 10/11/26.
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
