import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../core/services/magnification_service.dart';
import '../core/services/vibration_service.dart';

/// Widget that provides a movable magnifying lens over content
class MagnificationWrapper extends StatefulWidget {
  final Widget child;
  
  const MagnificationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MagnificationWrapper> createState() => _MagnificationWrapperState();
}

class _MagnificationWrapperState extends State<MagnificationWrapper> {
  Offset? _lensPosition;
  bool _showInstruction = true;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MagnificationService(),
      builder: (context, _) {
        final magnificationService = MagnificationService();
        
        if (!magnificationService.isEnabled) {
          _showInstruction = true;
          return widget.child;
        }

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final wasNull = _lensPosition == null;
              _lensPosition = details.localPosition;
              _showInstruction = false;
              
              // Vibrate when lens first appears
              if (wasNull) {
                VibrationService.mediumFeedback();
              }
            });
          },
          onTapDown: (details) {
            setState(() {
              final wasNull = _lensPosition == null;
              _lensPosition = details.localPosition;
              _showInstruction = false;
              
              // Vibrate when lens first appears
              if (wasNull) {
                VibrationService.mediumFeedback();
              }
            });
          },
          onTapUp: (_) {
            // Vibrate when lens disappears
            VibrationService.mediumFeedback();
            setState(() {
              _lensPosition = null;
            });
          },
          onPanEnd: (_) {
            // Vibrate when lens disappears
            VibrationService.mediumFeedback();
            setState(() {
              _lensPosition = null;
            });
          },
          child: Stack(
            children: [
              RepaintBoundary(
                key: _repaintKey,
                child: widget.child,
              ),
              if (_lensPosition != null)
                Positioned(
                  left: _lensPosition!.dx - 125,
                  top: _lensPosition!.dy - 125,
                  child: IgnorePointer(
                    child: _MagnifyingLens(
                      position: _lensPosition!,
                      repaintKey: _repaintKey,
                    ),
                  ),
                ),
              if (_showInstruction && _lensPosition == null)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Tap or drag anywhere to magnify',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MagnifyingLens extends StatefulWidget {
  final Offset position;
  final GlobalKey repaintKey;

  const _MagnifyingLens({
    required this.position,
    required this.repaintKey,
  });

  @override
  State<_MagnifyingLens> createState() => _MagnifyingLensState();
}

class _MagnifyingLensState extends State<_MagnifyingLens> {
  ui.Image? _image;

  @override
  void didUpdateWidget(_MagnifyingLens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _captureImage();
    }
  }

  @override
  void initState() {
    super.initState();
    _captureImage();
  }

  Future<void> _captureImage() async {
    try {
      final boundary = widget.repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        if (mounted) {
          setState(() {
            _image = image;
          });
        }
      }
    } catch (e) {
      // Ignore errors during capture
    }
  }

  @override
  Widget build(BuildContext context) {
    const lensSize = 250.0;
    const magnification = 1.8;
    
    return Container(
      width: lensSize,
      height: lensSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
        color: Colors.white,
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _MagnifierPainter(
            image: _image,
            position: widget.position,
            magnification: magnification,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
}

class _MagnifierPainter extends CustomPainter {
  final ui.Image? image;
  final Offset position;
  final double magnification;

  _MagnifierPainter({
    required this.image,
    required this.position,
    required this.magnification,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    
    canvas.save();
    
    // Clip to circle
    final clipPath = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.clipPath(clipPath);
    
    // The image is captured at 2.0 pixel ratio, so we need to scale positions
    const pixelRatio = 2.0;
    final scaledPosition = position * pixelRatio;
    
    // Calculate the area we want to magnify from the source image
    final sourceSize = (size.width / magnification) * pixelRatio;
    final sourceRect = Rect.fromCenter(
      center: scaledPosition,
      width: sourceSize,
      height: sourceSize,
    );
    
    // Draw into the full lens area
    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw the magnified portion
    canvas.drawImageRect(
      image!,
      sourceRect,
      destRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MagnifierPainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.position != position ||
           oldDelegate.magnification != magnification;
  }
}
