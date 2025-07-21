//
//  MapLocation 2.swift
//  Chat
//
//  Created by Malik on 21/07/2025.
//
import SwiftUI
import MapKit

public struct MapLocation: Identifiable, Sendable {
   public let id = UUID()
   public let coordinate: CLLocationCoordinate2D
}
