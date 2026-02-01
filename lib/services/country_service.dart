import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country_model.dart';

class CountryService {
  static const String _baseUrl =
      'https://restcountries.com/v3.1/all?fields=name,capital,population,region,flags,area';

  Future<List<Country>> fetchCountries() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Country.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }
}
