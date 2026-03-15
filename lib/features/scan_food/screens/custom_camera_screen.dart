import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';

class CustomScannerCameraScreen extends StatefulWidget {
  final bool initialIsDishMode;
  const CustomScannerCameraScreen({super.key, required this.initialIsDishMode});

  @override
  State<CustomScannerCameraScreen> createState() => _CustomScannerCameraScreenState();
}

class _CustomScannerCameraScreenState extends State<CustomScannerCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  late bool _isDishMode;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _isDishMode = widget.initialIsDishMode;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Camera initialization error: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final nextMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(nextMode);
    setState(() {
      _flashMode = nextMode;
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, {
          'file': File(file.path),
          'isDishMode': _isDishMode,
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color scaffoldBg = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // 1. App Header/Logo
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, color: AppTheme.brandBlue, size: 28.scale),
                SizedBox(height: 8.h),
                Text(
                  "AI SCANNER",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppTheme.brandBlue.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scanner Window (Moved higher)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 325.w, // Slightly wider
                  height: 410.h, // Slightly taller
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(30.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                        blurRadius: 25.scale,
                        spreadRadius: 2.scale,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(6.scale),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.scale),
                    child: Stack(
                      children: [
                        // The actual camera "Window"
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.previewSize?.height ?? 1,
                              height: _controller!.value.previewSize?.width ?? 1,
                              child: CameraPreview(_controller!),
                            ),
                          ),
                        ),
                        
                        // Glassy Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Corners
                        _buildCorner(isTop: true, isLeft: true),
                        _buildCorner(isTop: true, isLeft: false),
                        _buildCorner(isTop: false, isLeft: true),
                        _buildCorner(isTop: false, isLeft: false),

                        // Center Prompt
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(25.scale),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Text(
                              _isDishMode ? "วางอาหารในกรอบ" : "วางวัตถุดิบในกรอบ",
                              style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode Selector (Top white bar style)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(15.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeLabel("หาเมนูอาหาร", _isDishMode, () => setState(() => _isDishMode = true)),
                      _buildModeLabel("แนะนำสิ่งที่มี", !_isDishMode, () => setState(() => _isDishMode = false)),
                    ],
                  ),
                ),

                // Main Controls (Blue/Purple Gradient Tab)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16.h),
                  padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brandBlue, AppTheme.brandPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30.scale),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandPurple.withOpacity(0.3),
                        blurRadius: 15.scale,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomTextButton("ยกเลิก", () => Navigator.pop(context), true),
                      
                      _buildBottomIcon(Icons.refresh, () {}, true), // Added refresh icon as per reference

                      // Capture Button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          padding: EdgeInsets.all(3.scale),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                          ),
                          child: Container(
                            width: 62.scale,
                            height: 62.scale,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt, 
                              color: _isDishMode ? AppTheme.brandBlue : AppTheme.brandPurple, 
                              size: 28.scale
                            ),
                          ),
                        ),
                      ),

                      _buildBottomIcon(Icons.photo_library, () => Navigator.pop(context, "GALLERY"), true),
                      
                      _buildBottomTextButton("เรียบร้อย", () {}, true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon({required IconData icon, required VoidCallback onTap, bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.scale),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22.scale),
      ),
    );
  }

  Widget _buildModeLabel(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppTheme.brandBlue : Colors.grey[600],
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBottomTextButton(String text, VoidCallback onTap, [bool isWhite = false]) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: isWhite ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87), 
          fontSize: 14.sp, 
          fontWeight: FontWeight.w600
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, VoidCallback onTap, [bool isWhite = false]) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: isWhite ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87), size: 24.scale),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Positioned(
      top: isTop ? 0 : null,
      bottom: !isTop ? 0 : null,
      left: isLeft ? 0 : null,
      right: !isLeft ? 0 : null,
      child: Container(
        width: 30.scale,
        height: 30.scale,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
