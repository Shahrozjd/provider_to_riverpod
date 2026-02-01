class Country {
  final String name;
  final String capital;
  final int population;
  final String region;
  final String flag;
  final double area;

  Country({
    required this.name,
    required this.capital,
    required this.population,
    required this.region,
    required this.flag,
    required this.area,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] ?? 'Unknown',
      capital: (json['capital'] != null && json['capital'].isNotEmpty)
          ? json['capital'][0]
          : 'N/A',
      population: json['population'] ?? 0,
      region: json['region'] ?? 'Unknown',
      flag: json['flags']['png'] ?? '',
      area: (json['area'] ?? 0).toDouble(),
    );
  }
}
