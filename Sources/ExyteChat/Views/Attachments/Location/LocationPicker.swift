//
//  LocationPicker.swift
//  Chat
//
//  Created by Malik on 21/07/2025.
//
import SwiftUI
import MapKit

struct LocationPicker: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = LocationManager() // <-- ADD

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.5553, longitude: 69.2075),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var onLocationPicked: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack {
            Text("Tap the map to pick a location")
                .font(.headline)
                .padding()

            TappableMapView(region: $region, selectedCoordinate: $selectedCoordinate)

            HStack {
                Button {
                    if let myLocation = locationManager.currentLocation {
                        selectedCoordinate = myLocation
                        region.center = myLocation
                    }
                } label: {
                    Label("Use My Location", systemImage: "location.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
                .padding()

                Button {
                    let coordinateToSend = selectedCoordinate ?? region.center
                    onLocationPicked(coordinateToSend)
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Select This Location", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
                .padding()
                .disabled(selectedCoordinate == nil)

                   }
                   .padding()
        }
    }
}
