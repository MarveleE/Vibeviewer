//
//  VibeviewerApp.swift
//  Vibeviewer
//
//  Created by Groot chen on 2025/8/24.
//

import SwiftUI

@main
struct VibeviewerApp: App {
    @State private var dataModel = CursorDataModel()

    var body: some Scene {
        MenuBarExtra("Vibeviewer", systemImage: "bolt.fill") {
            MenuPopoverView(model: dataModel)
        }
    }
}
