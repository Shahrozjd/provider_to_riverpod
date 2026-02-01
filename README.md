# Provider vs Riverpod: Complete Comparison Guide

This document explains the key differences between Provider and Riverpod state management implementations in our Countries Explorer app.
A repository to understand Riverpod as a state management/ViewModel if you have worked with Provider. This project was built with antigravity following MVVM.

---

## Table of Contents
1. [State Management Layer](#1-state-management-layer)
2. [View Layer](#2-view-layer)
3. [App Setup](#3-app-setup)
4. [Key Differences Summary](#key-differences-summary)
5. [Why Riverpod is Better](#why-riverpod-is-better)

---

## 1. State Management Layer

### Provider Approach (Old)

```dart
import 'package:flutter/material.dart';
import '../models/country_model.dart';
import '../services/country_service.dart';

class CountryProvider extends ChangeNotifier {
  final CountryService _countryService = CountryService();

  // Mutable state variables
  List<Country> _countries = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters to expose state
  List<Country> get countries => _countries;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchCountries() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();  // ← Must manually notify

    try {
      _countries = await _countryService.fetchCountries();
      _isLoading = false;
      notifyListeners();  // ← Must manually notify
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();  // ← Must manually notify
    }
  }
}
```

**Characteristics:**
- ✅ Extends `ChangeNotifier`
- ⚠️ **Mutable state** - directly modifies variables
- ⚠️ Must manually call `notifyListeners()` after every change
- ⚠️ Service instantiated directly in provider
- ⚠️ Easy to forget `notifyListeners()` calls
- ⚠️ State can be accidentally modified from anywhere

---

### Riverpod Approach (New)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/country_model.dart';
import '../services/country_service.dart';

// Step 1: Create immutable state class
class CountryState {
  final List<Country> countries;
  final bool isLoading;
  final String errorMessage;

  CountryState({
    this.countries = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  // Method to create new state with updated values
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

// Step 2: Create StateNotifier to manage state
class CountryNotifier extends StateNotifier<CountryState> {
  final CountryService _countryService;

  CountryNotifier(this._countryService) : super(CountryState());

  Future<void> fetchCountries() async {
    // Update state immutably - automatically notifies listeners
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final countries = await _countryService.fetchCountries();
      state = state.copyWith(countries: countries, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }
}

// Step 3: Create providers for dependency injection
final countryServiceProvider = Provider<CountryService>((ref) {
  return CountryService();
});

final countryProvider = StateNotifierProvider<CountryNotifier, CountryState>((ref) {
  final service = ref.watch(countryServiceProvider);
  return CountryNotifier(service);
});
```

**Characteristics:**
- ✅ **Immutable state** - `CountryState` class with `copyWith()`
- ✅ `StateNotifier` automatically notifies when `state` is reassigned
- ✅ **Dependency injection** - service provided via provider
- ✅ Type-safe state management
- ✅ No manual `notifyListeners()` needed
- ✅ State can only be modified through StateNotifier methods
- ✅ Compile-time safety

---

## 2. View Layer

### Provider Approach (Old)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/country_provider.dart';

class CountriesView extends StatefulWidget {
  const CountriesView({super.key});

  @override
  State<CountriesView> createState() => _CountriesViewState();
}

class _CountriesViewState extends State<CountriesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use context to access provider
      context.read<CountryProvider>().fetchCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Countries')),
      body: Consumer<CountryProvider>(  // ← Consumer widget wraps UI
        builder: (context, provider, child) {
          // Access state through provider
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          return ListView.builder(
            itemCount: provider.countries.length,
            itemBuilder: (context, index) {
              final country = provider.countries[index];
              return ListTile(title: Text(country.name));
            },
          );
        },
      ),
    );
  }
}
```

**Characteristics:**
- ✅ Uses `StatefulWidget` and `State`
- ⚠️ Requires `BuildContext` to access provider
- ⚠️ Uses `Consumer<CountryProvider>` widget (extra layer)
- ⚠️ `context.read<CountryProvider>()` for actions
- ⚠️ Need to be careful with context scope
- ⚠️ More verbose code

---

### Riverpod Approach (New)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/country_provider.dart';

class CountriesView extends ConsumerStatefulWidget {  // ← ConsumerStatefulWidget
  const CountriesView({super.key});

  @override
  ConsumerState<CountriesView> createState() => _CountriesViewState();
}

class _CountriesViewState extends ConsumerState<CountriesView> {  // ← ConsumerState
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use ref to access provider (no context needed)
      ref.read(countryProvider.notifier).fetchCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider state directly
    final countryState = ref.watch(countryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Countries')),
      body: _buildBody(countryState),
    );
  }

  Widget _buildBody(CountryState state) {
    // Access state directly
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage.isNotEmpty) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }

    return ListView.builder(
      itemCount: state.countries.length,
      itemBuilder: (context, index) {
        final country = state.countries[index];
        return ListTile(title: Text(country.name));
      },
    );
  }
}
```

**Characteristics:**
- ✅ Uses `ConsumerStatefulWidget` and `ConsumerState`
- ✅ Access via `ref` instead of `context`
- ✅ `ref.watch(countryProvider)` to observe state
- ✅ `ref.read(countryProvider.notifier)` for actions
- ✅ No need for `Consumer` widget wrapper
- ✅ Cleaner, more direct code
- ✅ Can access providers from anywhere with `ref`

---

## 3. App Setup

### Provider Approach (Old)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/country_provider.dart';
import 'views/countries_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(  // ← Declare provider in widget tree
      create: (_) => CountryProvider(),
      child: MaterialApp(
        home: const CountriesView(),
      ),
    );
  }
}

// For multiple providers, need MultiProvider:
// MultiProvider(
//   providers: [
//     ChangeNotifierProvider(create: (_) => CountryProvider()),
//     ChangeNotifierProvider(create: (_) => UserProvider()),
//   ],
//   child: MaterialApp(...),
// )
```

**Characteristics:**
- ⚠️ Must declare providers in widget tree
- ⚠️ Need `MultiProvider` for multiple providers
- ⚠️ Provider scope tied to widget tree
- ⚠️ More boilerplate for complex apps

---

### Riverpod Approach (New)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/countries_view.dart';

void main() {
  runApp(
    const ProviderScope(  // ← Single ProviderScope at root
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CountriesView(),
    );
  }
}

// Providers are defined globally in provider files
// No need to declare them in widget tree!
```

**Characteristics:**
- ✅ Single `ProviderScope` at root
- ✅ Providers defined globally (in provider files)
- ✅ No need to declare providers in widget tree
- ✅ Cleaner, simpler setup
- ✅ Easy to add more providers without changing main.dart

---

## Key Differences Summary

| Aspect | Provider | Riverpod |
|--------|----------|----------|
| **State Type** | Mutable | Immutable |
| **Base Class** | `ChangeNotifier` | `StateNotifier<T>` |
| **Notification** | Manual `notifyListeners()` | Automatic on state assignment |
| **Access Method** | `context.read/watch` | `ref.read/watch` |
| **Widget Type** | `Consumer<T>` | `ConsumerWidget/ConsumerStatefulWidget` |
| **Setup** | `ChangeNotifierProvider` in tree | `ProviderScope` at root |
| **Type Safety** | Good | Excellent (compile-time) |
| **Dependency Injection** | Manual | Built-in with providers |
| **Testing** | Harder (needs context) | Easier (no context needed) |
| **Context Required** | Yes | No |
| **Provider Declaration** | In widget tree | Global |
| **Multiple Providers** | `MultiProvider` | Just define more providers |

---

## Why Riverpod is Better

### 1. 🔒 **Immutability**
- State changes are predictable and traceable
- No accidental mutations
- Easier to debug state changes

### 2. 🎯 **Type Safety**
- Catch errors at compile-time, not runtime
- IDE autocomplete works better
- Refactoring is safer

### 3. 🧪 **Testability**
- No BuildContext needed for testing
- Providers can be easily mocked
- Unit tests are simpler to write

### 4. ⚡ **Performance**
- Fine-grained reactivity
- Only rebuilds widgets that watch changed providers
- Better optimization opportunities

### 5. 🔌 **Dependency Injection**
- Built-in, automatic, and type-safe
- Easy to swap implementations
- Clear dependency graph

### 6. 📦 **No Context Required**
- Access providers from anywhere using `ref`
- No need to pass context around
- Cleaner architecture

### 7. 🛡️ **Safety**
- Can't forget to call `notifyListeners()`
- State can only be modified through defined methods
- Compile-time checks prevent many bugs

### 8. 🚀 **Modern Architecture**
- Follows Flutter best practices
- Better suited for large applications
- Recommended by Flutter team for new projects

---

## Quick Reference: Common Operations

### Watching State Changes

**Provider:**
```dart
Consumer<CountryProvider>(
  builder: (context, provider, child) {
    return Text('Count: ${provider.countries.length}');
  },
)
```

**Riverpod:**
```dart
// In ConsumerWidget/ConsumerStatefulWidget
final state = ref.watch(countryProvider);
return Text('Count: ${state.countries.length}');
```

---

### Triggering Actions

**Provider:**
```dart
context.read<CountryProvider>().fetchCountries();
```

**Riverpod:**
```dart
ref.read(countryProvider.notifier).fetchCountries();
```

---

### Accessing State Without Rebuilding

**Provider:**
```dart
final provider = context.read<CountryProvider>();
print(provider.countries.length);
```

**Riverpod:**
```dart
final state = ref.read(countryProvider);
print(state.countries.length);
```

---

## Conclusion

While both Provider and Riverpod are excellent state management solutions, **Riverpod** offers:
- Better type safety
- Improved testability
- Cleaner architecture
- More predictable state management
- Better performance
- Modern best practices

For new projects, **Riverpod is the recommended choice**. The migration from Provider to Riverpod is straightforward and worth the effort for the benefits it provides!
