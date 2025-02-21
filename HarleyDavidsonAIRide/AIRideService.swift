import Foundation
import CoreLocation

struct Route: Codable {
  let waypoints: [Location]
  let distance: Double
}

struct Location: Codable, Identifiable {
  
//  enum CodingKeys: String, CodingKey {
//    case id = "id"
//    case latitude = "latitude"
//    case longitude = "longitude"
//  }
  
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = UUID.init()
    name = try container.decode(String.self, forKey: .name)
    latitude = try container.decode(Double.self, forKey: .latitude)
    longitude = try container.decode(Double.self, forKey: .longitude)
  }
  
  
  let id: UUID
  let name: String
  let latitude: CLLocationDegrees
  let longitude: CLLocationDegrees
}



class AIRideService {
  
  enum Error: Swift.Error {
    case invalidResponse
  }
  
  func getRoute(_ location: CLLocationCoordinate2D) async throws -> Route {
    var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer Token-Redacted", forHTTPHeaderField: "Authorization")
    
    urlRequest.httpBody = try getHTTPBodyForStartingLocation(location)
    
    print("body", String(data: urlRequest.httpBody!, encoding: .utf8))
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    print(response)
    print(data)
    
    if let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) {
      print("HTTP Body Request", bodyString)
    }
    
    
    let str = String(data: data, encoding: .utf8)
    
    print(str)
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let choices = json["choices"] as? [[String: Any]],
          let content = choices.first?["message"] as? [String: Any],
          let rawContent = content["content"] as? String
    else { throw Error.invalidResponse }
    print("Response rawContent", rawContent) // Outputs the desired JSON structure
    
    
    let jsonData = rawContent.data(using: .utf8)
    let route = try! JSONDecoder().decode(Route.self, from: jsonData!)
    print("Route", route)
    return route
  }
    
  private func getHTTPBodyForStartingLocation(_ location: CLLocationCoordinate2D) -> Data? {
    """
    {
      "model": "gpt-4-turbo",
      "messages": [
        {
          "role": "system",
          "content": "Generate a complete JSON response without truncation in the content response field. You are a motorbike route planner. The user is starting from a given location and wants to take a scenic ride within a specified distance range. You should generate a list of waypoints for a motorbike route, with locations that are within 100 to 120 miles of the starting point. The waypoints should be described with the following fields: 'name' (location name), 'latitude' (latitude in decimal format), 'longitude' (longitude in decimal format). Add route distance in miles in distance property. The generated waypoints should be suitable for use in Apple Maps and provide a scenic route.  Start and Finish at same location. Include start and end latlong waypoints. Give preference to more circular routes. Ensure that the JSON is valid (after removing escape chars. Do not put any extra chars before or after the json in the content field. Do not send an incomplete response - ensure full JSON is sent in content field. The response should be structured as follows: {\\\"waypoints\\\": [{\\\"name\\\": String, \\\"latitude\\\": Double, \\\"longitude\\\": Double}], \\\"distance\\\": Double}"
        },
        {
          "role": "user",
          "content": "Starting location: LATITUDE: \(location.latitude), LONGITUDE: \(location.longitude). The trip should be a scenic ride within 100 to 120 miles of the starting point. Provide the waypoints in JSON format suitable for use in Apple Maps."
        }
      ],
      "temperature": 0.7,
      "max_tokens": 400,
      "stream": false
    }
    
    
    
    
    """.data(using: .utf8)
  }
  
  private func getHTTPBodyForStockRecommendations(with priorQuestionsJson: String) -> Data? {
    """
    {
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content": "You are a stock investment advisor. Provide a list of 3 stock choices based on the answers to questions already provided. Double check that the stocks fit the answers provided. Ensure that the JSON is valid (after removing escape chars. Do not put any extra chars before or after the json in the content field. Do not send an incomplete response - ensure full JSON is sent in content field. The response should be structured as follows: {\\\"text\\\": \\\"These stocks fit your investment criterion:\\\", \\\"options\\\": [{\\\"id\\\": \\\"A\\\", \\\"answer\\\": \\\"answer text here\\\", \\\"explanation\\\": \\\"Explanation of the option here\\\"}, {\\\"id\\\": \\\"B\\\", \\\"option\\\": \\\"Option text here\\\", \\\"explanation\\\": \\\"Explanation of the option here\\\"}, {\\\"id\\\": \\\"C\\\", \\\"answer\\\": \\\"answer text here\\\", \\\"explanation\\\": \\\"Explanation of the option here\\\"}]}"
        },
        {
          "role": "user",
          "content": "Provide 3 stocks that exist in the S&P 500 that fit the criteria of answers given to prior questions. Use latest data for recommendations. Prior Questions and answers chosen by user: \(priorQuestionsJson)"
        }
      ],
      "temperature": 0,
      "max_tokens": 200,
      "stream": false 
    }
    
    """.data(using: .utf8)
  }
  
}


struct InvestmentQuestion: Codable {
  let text: String
  let options: [Option]
  var selectedOptionId: String?
  
  enum CodingKeys: String, CodingKey {
    case text
    case options
  }
  
  // Custom encode method to omit `selectedOptionId`
  // and selected item from `options` during encoding for sending to ChatGPT
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(text, forKey: .text)
    // Just add selected option
    try container.encode(options.filter { $0.id == selectedOptionId }, forKey: .options)
    // Omit `selectedOptionId` while encoding
  }
  
  struct Option: Codable, Identifiable, Hashable {
    let id: String
    let answer: String
    let explanation: String
    
    
    enum CodingKeys: String, CodingKey {
      case id
      case answer
      case explanation
    }
    
    // Custom encode method to omit `secret` during encoding for sending to ChatGPT
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(answer, forKey: .answer)
      // Omit `explanation` while encoding
    }
  }
}

