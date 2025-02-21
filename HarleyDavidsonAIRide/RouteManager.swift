import MapKit

class RouteManager {
  
  func calculateRouteFrom(_ startingPoint: CLLocationCoordinate2D) async throws -> ([CLLocationCoordinate2D], Route) {
    
    let route = try await AIRideService().getRoute(startingPoint)
    
    let routeWaypoints = route.waypoints.map { CLLocationCoordinate2D.init(latitude: .init($0.latitude), longitude: .init($0.longitude)) }
    
    let routeCoords = await MapService().mapRouteCoordinates(for: routeWaypoints)
    
    return (routeCoords, route)
  }
}


