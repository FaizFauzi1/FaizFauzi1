import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiExtractionService {
  static Future<List<Map<String, dynamic>>?> extractServiceDetailsFromPdf(Uint8List pdfBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
        debugPrint('AI_EXTRACTION: GEMINI_API_KEY is missing or invalid.');
        return null;
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
You are an AI assistant that extracts service and product information from PDF brochures for a vendor platform. 
Please extract ALL services, packages, and products from this brochure.
If a piece of information is not explicitly found, make a best guess based on the context, or leave the field empty/null.

The output MUST be a JSON ARRAY of objects (e.g. `[{}, {}]`), even if there is only one service.
Each JSON object MUST have the following keys:
- "name": (String) The name of the service, product, or package.
- "description": (String) A comprehensive description of the service.
- "price": (Double) A numeric value representing the base price (do not include currency symbols).
- "duration": (String) A numeric string representing the typical duration (e.g., "2", "30").
- "durationUnit": (String) Must be "Hours", "Days", or "Minutes".
- "serviceType": (String) Determine based on context. Must be one of: "service", "package", "product", "rental", or "venue".
- "stockQuantity": (Integer) Numeric value for inventory (only if it's a product or rental).
- "minQty": (Integer) Minimum order quantity (if specified).

Return ONLY valid JSON.
''';

      debugPrint('AI_EXTRACTION: Sending request to Gemini...');
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('application/pdf', pdfBytes),
        ])
      ];

      final response = await model.generateContent(content);
      
      final responseText = response.text;
      debugPrint('AI_EXTRACTION: Received response: $responseText');
      
      if (responseText != null && responseText.isNotEmpty) {
        // Strip markdown code block markers if present
        var cleanedText = responseText.trim();
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText.substring(7);
        } else if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText.substring(3);
        }
        if (cleanedText.endsWith('```')) {
          cleanedText = cleanedText.substring(0, cleanedText.length - 3);
        }
        cleanedText = cleanedText.trim();
        
        final decoded = jsonDecode(cleanedText);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map) {
          return [Map<String, dynamic>.from(decoded)];
        }
      }
      return null;
    } catch (e) {
      debugPrint('AI_EXTRACTION_ERROR: $e');
      return null;
    }
  }
}
