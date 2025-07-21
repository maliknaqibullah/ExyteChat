import SwiftUI
import MapKit
import Combine

struct LiveLocationView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var region: MKCoordinateRegion

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapLocation(coordinate: region.center)]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                Image(systemName: "location.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.blue)
                    .shadow(radius: 4)
            }
        }
        .frame(height: 300)
        .cornerRadius(16)
        .padding()
    }
}
