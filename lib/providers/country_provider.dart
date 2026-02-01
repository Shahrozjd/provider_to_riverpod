import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/country_model.dart';
import '../services/country_service.dart';

// State class to hold countries data and loading/error states
class CountryState {
  final List<Country> countries;
  final bool isLoading;
  final String errorMessage;

  CountryState({
    this.countries = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  CountryState copyWith({
    List<Country>? countries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CountryState(
      countries: countries ?? this.countries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// StateNotifier for managing country state
class CountryNotifier extends StateNotifier<CountryState> {
  final CountryService _countryService;

  CountryNotifier(this._countryService) : super(CountryState());

  Future<void> fetchCountries() async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final countries = await _countryService.fetchCountries();
      state = state.copyWith(countries: countries, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }
}

// Provider for CountryService
final countryServiceProvider = Provider<CountryService>((ref) {
  return CountryService();
});

// Provider for CountryNotifier
final countryProvider = StateNotifierProvider<CountryNotifier, CountryState>((
  ref,
) {
  final service = ref.watch(countryServiceProvider);
  return CountryNotifier(service);
});
