import 'dart:convert';
import '../models/medication_inquiry.dart';
import '../models/message.dart';
import 'api_service.dart';

class InquiryService {
  final ApiService _apiService = ApiService();

  Future<List<MedicationInquiry>> getUserInquiries() async {
    try {
      final response = await _apiService.getMyMedicationInquiries();
      return response;
    } catch (e) {
      throw Exception('Failed to load inquiries: $e');
    }
  }

  Future<MedicationInquiry> getInquiryDetails(int inquiryId) async {
    try {
      final messages = await _apiService.getMedicationInquiryMessages(inquiryId);
      if (messages.isNotEmpty) {
        final Message firstMessage = messages.first;
        if (firstMessage.inquiry != null) {
          return MedicationInquiry.fromJson(firstMessage.inquiry!);
        }
      }
      throw Exception('Inquiry not found');
    } catch (e) {
      throw Exception('Failed to load inquiry details: $e');
    }
  }

  Future<void> createInquiry(String medicationName, String patientNote) async {
    try {
      await _apiService.createMedicationInquiry(medicationName, patientNote);
    } catch (e) {
      throw Exception('Failed to create inquiry: $e');
    }
  }

  Future<void> sendMessage(int inquiryId, String content) async {
    try {
      await _apiService.sendInquiryMessage(inquiryId, content);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> closeInquiry(int inquiryId) async {
    try {
      // TODO: Implement close inquiry endpoint
      throw UnimplementedError('Close inquiry not implemented yet');
    } catch (e) {
      throw Exception('Failed to close inquiry: $e');
    }
  }
}
