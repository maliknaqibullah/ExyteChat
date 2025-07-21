//
//  LiveLocationSharingScreen.swift
//  Chat
//
//  Created by Malik on 21/07/2025.
//


import SwiftUI
import MapKit

struct LiveLocationSharingScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var selectedMinutes: Int = 15
    @State private var isSharing = false
    @State private var timer: Timer?

    var onStopSharing: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 🗺️ Top: Map
            LiveLocationView(locationManager: locationManager, region: $region)

            if isSharing {
                // 🛑 Stop button
                Button {
                    stopSharing()
                } label: {
                    Label("Stop Sharing", systemImage: "xmark.circle.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.large)
                .padding()
            } else {
                // ⏱️ Duration picker + Start button
                LiveLocationDurationPicker(selectedMinutes: $selectedMinutes) {
                    startSharing()
                }
            }
        }
        .onReceive(locationManager.locationPublisher) { coord in
            withAnimation {
                region.center = coord
            }
        }
    }

    private func startSharing() {
        isSharing = true
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(selectedMinutes * 60), repeats: false) { _ in
            stopSharing()
        }
    }

    private func stopSharing() {
        isSharing = false
        timer?.invalidate()
        timer = nil
        onStopSharing()
    }
}
