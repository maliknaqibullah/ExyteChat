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
                       Button("Use My Location") {
                           if let myLocation = locationManager.currentLocation {
                               selectedCoordinate = myLocation
                               region.center = myLocation
                           }
                       }

                       Button("Select This Location") {
                           let coordinateToSend = selectedCoordinate ?? region.center
                           onLocationPicked(coordinateToSend)
                           presentationMode.wrappedValue.dismiss()
                       }
                       .disabled(selectedCoordinate == nil)
                   }
                   .padding()
        }
    }
}
