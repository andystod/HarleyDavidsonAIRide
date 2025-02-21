import SwiftUI
import MapKit

struct OldLocation: Identifiable {
  let id: Int
  let coordinate: CLLocationCoordinate2D
}

struct RideMapView: View {
   
  @State private var routeCoordinates: [CLLocationCoordinate2D] = []
  @State private var route: Route?
  
  @State private var searchResults: [MKMapItem] = []
  
  private let userLocation = CLLocationCoordinate2D(latitude: .init(34.00806383605978), longitude: .init(-118.49929084949056))
  
  
  
  var body: some View {
    //    Text("Hello")
    
    
    //    Self._printChanges()
    
    
    Map(initialPosition: MapCameraPosition.region(MKCoordinateRegion(
      center: userLocation,
      span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    ))) {
      if !routeCoordinates.isEmpty {
        MapPolyline(coordinates: routeCoordinates)
          .stroke(.blue, lineWidth: 2)
      }
      if let route = route, let start = route.waypoints.first {
        Marker("Start/Finish", coordinate: .init(latitude: start.latitude, longitude: start.longitude))
      }
      if let stops = route?.waypoints.dropFirst().dropLast(), !stops.isEmpty {
        ForEach(stops) { stop in
          Marker(stop.name, systemImage: "binoculars.fill", coordinate: .init(latitude: stop.latitude, longitude: stop.longitude))
            .tint(.green)
        }
      }
      
      ForEach(searchResults, id: \.self) { result in
        Marker(item: result)
      }
      
      
    }.onAppear {
      Task {
//        polyline = await RouteService().calculatePolyline(for: locations.map { $0.coordinate})
        do {
          (routeCoordinates, route) = try await RouteManager().calculateRouteFrom(userLocation)
          
//          if let waypoints = route?.waypoints {
//            searchResults = await MapService().search(for: .restaurant, in: waypoints.map { .init(latitude: $0.latitude, longitude: $0.longitude) })
//          }
//          print("routeCoordinates", routeCoordinates)
//          print("searchResults", searchResults)
          
        } catch {
          print(error)
        }
        
      }
    }
  }
}

struct RouteMapView_Previews: PreviewProvider {
  static var previews: some View {
    RideMapView()
    //    RouteMapView(route: MapViewModel(
    //      waypoints: [
    //        CLLocationCoordinate2D(latitude: 34.1184, longitude: -118.3004),
    //        CLLocationCoordinate2D(latitude: 34.1478, longitude: -118.1445),
    //        CLLocationCoordinate2D(latitude: 34.3217, longitude: -118.0058)
    //      ],
    //      route: MKRoute() // Add a valid MKRoute object in a real case
    //    ))
  }
}
