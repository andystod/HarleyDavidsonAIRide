import MapKit

class MapService {
  
  func mapRouteCoordinates(for waypoints: [CLLocationCoordinate2D]) async -> [CLLocationCoordinate2D] {
    guard waypoints.count > 1 else { return [] }
    
    var routes = [MKRoute?](repeating: nil, count: waypoints.count - 1)
    
    await withTaskGroup(of: (Int, MKRoute?).self) { group in
      for i in 0..<waypoints.count - 1 {
        group.addTask { [weak self] in
          let route = await self?.calculateRoute(from: waypoints[i], to: waypoints[i + 1])
          return (i, route)
        }
      }
      
      for await (index, route) in group {
        routes[index] = route
      }
    }
    
    return mergedCoordinates(from: routes.compactMap { $0 })
  }
  
  private func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> MKRoute? {
    
    print("start", start, "end", end)
    
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
    request.transportType = .automobile
    request.requestsAlternateRoutes = false
    
    let directions = MKDirections(request: request)
    
    do {
      let response = try await directions.calculate()
      return response.routes.first
    } catch {
      print("Error calculating route from \(start) to \(end): \(error)")
      return nil
    }
  }
  
  private func mergedCoordinates(from routes: [MKRoute]) -> [CLLocationCoordinate2D] {
    guard !routes.isEmpty else { return [] }
    
    var merged: [CLLocationCoordinate2D] = []
    
    for (index, route) in routes.enumerated() {
      let polyline = route.polyline
      let pointCount = polyline.pointCount
      
      // Extract the segment’s coordinates
      var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
      polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
      
      // If this segment’s first coordinate is the same as
      // the last in `merged`, remove it to avoid duplication
      if index > 0, let lastCoord = merged.last, lastCoord == coords.first {
        coords.removeFirst()
      }
      
      merged.append(contentsOf: coords)
    }
    
    return merged
  }
}

extension MapService {
  
  func search(for searchFor: MKPointOfInterestCategory, in coordinates: [CLLocationCoordinate2D]) async -> [MKMapItem] {
    guard let region = boundingRegion(for: coordinates) else { return [] }
    
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = "restaurant"
    request.resultTypes = .pointOfInterest
    
    request.pointOfInterestFilter = MKPointOfInterestFilter(including: [searchFor])
    
    request.region = region
    
    //    request.region = MKCoordinateRegion(
    //      center: region.center,
    //      span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
    //    )
    
    //    request.region = MKCoordinateRegion(
    //      center: center,
    //      span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
    //    )
    
    let search = MKLocalSearch(request: request)
    let response = try? await search.start()
    return response?.mapItems ?? []
  }
  
  func searchRestaurants(in coordinates: [CLLocationCoordinate2D], maxResults: Int = 5) async -> [MKMapItem] {
    guard let region = boundingRegion(for: coordinates) else { return [] }
    
    let request = MKLocalSearch.Request()
    request.resultTypes = .pointOfInterest
    request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])
    request.region = region
    
    let search = MKLocalSearch(request: request)
    let response = try? await search.start()
    
    return response?.mapItems.prefix(maxResults).map { $0 } ?? []
  }
  
//  private func boundingRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
//    guard !coordinates.isEmpty else { return nil }
//    
//    let minLat = coordinates.map { $0.latitude }.min()!
//    let maxLat = coordinates.map { $0.latitude }.max()!
//    let minLon = coordinates.map { $0.longitude }.min()!
//    let maxLon = coordinates.map { $0.longitude }.max()!
//    
//    print("min max", minLat, maxLat, minLon, maxLon)
//    
//    let center = CLLocationCoordinate2D(
//      latitude: (minLat + maxLat) / 2,
//      longitude: (minLon + maxLon) / 2
//    )
//    let span = MKCoordinateSpan(
//      latitudeDelta: maxLat - minLat,
//      longitudeDelta: maxLon - minLon
//    )
//    
//    print("center span", center, span)
//    
//    return MKCoordinateRegion(center: center, span: span)
//  }
  
  private func boundingRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
      guard !coordinates.isEmpty else { return nil }
      
      let minLat = coordinates.map { $0.latitude }.min()!
      let maxLat = coordinates.map { $0.latitude }.max()!
      let minLon = coordinates.map { $0.longitude }.min()!
      let maxLon = coordinates.map { $0.longitude }.max()!

      print("min max", minLat, maxLat, minLon, maxLon)

      let center = CLLocationCoordinate2D(
          latitude: (minLat + maxLat) / 2,
          longitude: (minLon + maxLon) / 2
      )

      var latitudeDelta = maxLat - minLat
      var longitudeDelta = maxLon - minLon

      // Ensure a minimum span to avoid a zero-sized region
      let minSpan: CLLocationDegrees = 0.01 // ~1km
      latitudeDelta = max(latitudeDelta * 1.5, minSpan)
      longitudeDelta = max(longitudeDelta * 1.5, minSpan)

      let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

      print("Adjusted center & span", center, span)

      return MKCoordinateRegion(center: center, span: span)
  }
}

extension CLLocationCoordinate2D: @retroactive Equatable {}
extension CLLocationCoordinate2D: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    // Combine lat/long exactly (works if they're precise)
    hasher.combine(latitude)
    hasher.combine(longitude)
  }
  
  public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
}


