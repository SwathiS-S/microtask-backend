import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<Map<String, dynamic>> post(String endpoint, Map data) async { 
    try { 
      final response = await http.post( 
        Uri.parse("$baseUrl$endpoint"), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(data), 
      ).timeout(const Duration(seconds: 60)); // ← increase to 60s for Render cold start 
  
      if (response.body.isEmpty) { 
        return {"success": false, "message": "Server returned an empty response"}; 
      } 
  
      final dynamic decoded = jsonDecode(response.body); 
      if (decoded is Map<String, dynamic>) { 
        return decoded; 
      } else { 
        return {"success": false, "message": "Unexpected response format"}; 
      } 
    } catch (e) { 
      if (e.toString().contains('TimeoutException')) { 
        return {"success": false, "message": "Server is waking up, please try again in a moment."}; 
      } 
      return {"success": false, "message": "Connection error: ${e.toString()}"}; 
    } 
  } 

  static Future<Map<String, dynamic>> postFile(String endpoint, String filePath, Map<String, String> fields) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath('final', filePath));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "File upload error: ${e.toString()}"};
    }
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl$endpoint"))
          .timeout(const Duration(seconds: 15));
      
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      return null;
    }
  }
}
