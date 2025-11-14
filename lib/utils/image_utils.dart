import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class ImageUtils {
  /// Saves an image to the device's gallery
  /// Returns true if successful, false otherwise
  static Future<bool> saveImageToGallery(
    Uint8List imageBytes, {
    String? name,
    BuildContext? context,
  }) async {
    try {
      // Check if gallery access is available
      final bool hasAccess = await Gal.hasAccess();
      
      if (!hasAccess) {
        // Request permission
        final bool requestResult = await Gal.requestAccess();
        if (!requestResult) {
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gallery access permission is required to save images'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }

      // Generate filename if not provided
      final fileName = name ?? 'solari_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Save image to gallery
      await Gal.putImageBytes(
        imageBytes,
        name: fileName,
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error saving image to gallery: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}