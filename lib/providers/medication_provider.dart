import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../services/api_service.dart';

class MedicationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Medication> _searchResults = [];
  bool _isLoading = false;

  MedicationProvider(this._apiService);

  List<Medication> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> searchMedications(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchMedications(query);
    } catch (e) {
      _searchResults = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
