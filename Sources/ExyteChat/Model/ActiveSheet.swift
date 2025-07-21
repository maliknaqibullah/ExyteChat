//
//  ActiveSheet.swift
//  Chat
//
//  Created by Malik on 21/07/2025.
//


enum ActiveSheet: Identifiable {
    case documentPicker
    case locationPicker
    case attachmentPicker

    var id: String {
        switch self {
        case .documentPicker: return "documentPicker"
        case .locationPicker: return "locationPicker"
        case .attachmentPicker: return "attachmentPicker"
        }
    }
}
