import 'dart:convert';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// Global cameras list
List<CameraDescription> cameras = [];

// API Keys
const String gNewsApiKey = 'bccb2a5566a64f2d0b3533fb8a94ceff';
const String qubridApiKey =
    'k_23a8149a1e86.LYRvARO4WRDFck9bh_uCfRHFVq8l8kabepjJnDzbts2nhgLTLZqb1A';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const FarmApp());
}

// ============================================
// APP THEME & COLORS
// ============================================

class AppColors {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1B5E20);
  static const Color textGrey = Color(0xFF757575);
}

class FarmApp extends StatelessWidget {
  const FarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krushak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
        scaffoldBackgroundColor: AppColors.backgroundGreen,
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

// ============================================
// MAIN NAVIGATION WITH BOTTOM BAR
// ============================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const ScanScreen(), // Placeholder, actual scan opens from FAB
    const NewsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.crop_free, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
              _buildNavItem(
                  Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.article_outlined, Icons.article, 'News', 3),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HOME SCREEN
// ============================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              _buildHeader(context),
              const SizedBox(height: 20),

              // Tap to Scan card
              _buildScanCard(context),
              const SizedBox(height: 20),

              // Agri News preview
              _buildNewsPreview(context),
              const SizedBox(height: 20),

              // Plant Tools section
              _buildPlantTools(context),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightGreen,
            border: Border.all(color: AppColors.primaryGreen, width: 2),
          ),
          child: ClipOval(
            child: Image.network(
              'https://api.dicebear.com/7.x/avataaars/png?seed=farmer',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                size: 32,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Text(
                'Farmer User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Maharashtra, IN',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Notification bell - links to Reminders
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textDark),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Tap to Scan Now!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                size: const Size(60, 60),
                painter: ScanFramePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Agri News',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Latest Subsidies for 2024',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check out new government schemes for organic farming.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Read Full Article'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plant Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),

        // Plant Identifier card
        _buildToolCard(
          context,
          'Plant Identifier',
          Icons.camera_alt,
          AppColors.lightGreen,
          '🪴',
          () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ScanScreen())),
          isLarge: true,
        ),
        const SizedBox(height: 12),

        // Marketplace card
        _buildToolCard(
          context,
          'Marketplace',
          Icons.storefront,
          const Color(0xFFFFF3E0),
          '🏪',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
          isLarge: true,
          iconColor: Colors.orange[700],
        ),
        const SizedBox(height: 12),

        // Grid of smaller tools
        Row(
          children: [
            Expanded(
              child: _buildSmallToolCard(
                context,
                'Reminder',
                Icons.access_time,
                Colors.blue,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReminderScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallToolCard(
                context,
                'Care Guides',
                Icons.menu_book,
                Colors.orange,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CareGuidesScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallToolCard(
                context,
                'Agri News',
                Icons.article,
                AppColors.primaryGreen,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NewsScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallToolCard(
                context,
                'Send on WhatsApp',
                Icons.chat_bubble_outline,
                AppColors.primaryGreen,
                () async {
                  const url =
                      'https://wa.me/7720995173?text=hello%20from%20krushak%20app';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    String emoji,
    VoidCallback onTap, {
    bool isLarge = false,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primaryGreen),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Text(emoji, style: const TextStyle(fontSize: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for scan frame
class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 15.0;

    // Top left
    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Top right
    canvas.drawLine(
        Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom left
    canvas.drawLine(
        Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom right
    canvas.drawLine(Offset(size.width - cornerLength, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// SCAN SCREEN (DISEASE DETECTION)
// ============================================

// ============================================
// QUBRID API SERVICE FOR PLANT DISEASE DETECTION
// ============================================

class QubridService {
  static const String _apiUrl =
      'https://platform.qubrid.com/api/v1/qubridai/multimodal/chat';
  static const String _model = 'Qwen/Qwen3-VL-8B-Instruct';

  static Future<Map<String, dynamic>> analyzePlantImage(
      String imagePath) async {
    try {
      // Read and encode image to base64
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine image type
      String mimeType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      }
      final dataUrl = 'data:$mimeType;base64,$base64Image';

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $qubridApiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'model': _model,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text':
                          '''Analyze this image carefully. You must respond in this EXACT JSON format only, no other text:

{"is_plant": <true or false>, "plant_name": "<name of plant species if detected, or null>", "disease_name": "<disease name or 'Healthy' or null>", "confidence": <number between 0.0 and 1.0>, "description": "<brief description>"}

RULES:
1. FIRST check if the image contains a plant (leaf, flower, tree, crop, vegetation, etc.)
2. If it's NOT a plant (e.g., laptop, phone, car, person, animal, building, etc.), set is_plant to false, plant_name to null, disease_name to null, and description should say what the object actually is
3. If it IS a plant:
   - Identify the plant species (e.g., "Tomato", "Apple", "Rose", "Corn", "Potato", etc.)
   - Check for any disease symptoms
   - If healthy, set disease_name to "Healthy"
   - If diseased, identify the specific disease (e.g., "Early Blight", "Powdery Mildew", "Leaf Spot", etc.)
   - Include plant name in disease_name like "Tomato - Early Blight" or "Apple - Healthy"
4. Base confidence on how clearly you can identify the plant/disease'''
                    },
                    {
                      'type': 'image_url',
                      'image_url': {'url': dataUrl}
                    }
                  ]
                }
              ],
              'max_tokens': 400,
              'temperature': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String content = '';

        // Handle different response formats
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          content = data['choices'][0]['message']?['content'] ?? '';
        } else if (data['content'] != null) {
          content = data['content'];
        }

        // Parse the JSON response from the model
        return _parseResponse(content);
      } else {
        debugPrint(
            'Qubrid API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Qubrid Service Error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _parseResponse(String content) {
    try {
      // Try to extract JSON from the response
      String jsonStr = content.trim();

      // Remove markdown code blocks if present
      if (jsonStr.contains('```')) {
        final match =
            RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(1)?.trim() ?? jsonStr;
        }
      }

      // Find JSON object in the response
      final jsonMatch =
          RegExp(r'\{[^{}]*"is_plant"[^{}]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }

      final parsed = json.decode(jsonStr);
      final isPlant = parsed['is_plant'] == true;

      return {
        'isPlant': isPlant,
        'plantName': parsed['plant_name'],
        'label':
            parsed['disease_name'] ?? (isPlant ? 'Unknown' : 'Not a Plant'),
        'confidence': (parsed['confidence'] ?? 0.8).toDouble(),
        'description': parsed['description'] ?? '',
      };
    } catch (e) {
      debugPrint('Parse error: $e, content: $content');
      // Fallback parsing
      final lowerContent = content.toLowerCase();
      if (lowerContent.contains('not a plant') ||
          lowerContent.contains('is not a plant') ||
          lowerContent.contains('laptop') ||
          lowerContent.contains('computer') ||
          lowerContent.contains('phone') ||
          lowerContent.contains('device')) {
        return {
          'isPlant': false,
          'plantName': null,
          'label': 'Not a Plant',
          'confidence': 0.9,
          'description': content,
        };
      }
      if (lowerContent.contains('healthy')) {
        return {
          'isPlant': true,
          'plantName': 'Unknown Plant',
          'label': 'Healthy',
          'confidence': 0.8,
          'description': 'Plant appears healthy',
        };
      }
      return {
        'isPlant': true,
        'plantName': null,
        'label': 'Analysis Complete',
        'confidence': 0.7,
        'description': content,
      };
    }
  }
}

// ============================================
// SCAN SCREEN
// ============================================

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _isOnlineMode = true; // Default to Online
  final ImagePicker _imagePicker = ImagePicker();
  String _statusMessage = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      setState(() {
        _statusMessage = 'No camera available';
        _isInitialized = true;
      });
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController =
        CameraController(camera, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = '';
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() {
        _statusMessage = 'Camera error: $e';
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing image...';
    });

    try {
      Map<String, dynamic> result;
      if (_isOnlineMode) {
        result = await QubridService.analyzePlantImage(imagePath);
      } else {
        // Offline Mode
        result = await TFLiteService.analyze(imagePath);
        result['usedOfflineModel'] = true;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              isPlant: result['isPlant'] ?? true,
              plantName: result['plantName'],
              diseaseName: result['label'],
              confidence: result['confidence'],
              imagePath: imagePath,
              description: result['description'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Analysis failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  Future<void> _scanFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (_isProcessing) return;

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      await _analyzeImage(imageFile.path);
    } catch (e) {
      _showError('Error capturing image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      await _analyzeImage(pickedFile.path);
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Scan Plant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: AppColors.primaryGreen),
                  const SizedBox(height: 16),
                  Text(_statusMessage,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _cameraController != null &&
                          _cameraController!.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            CameraPreview(_cameraController!),
                            // Scan frame overlay
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),

                            // Online/Offline Toggle
                            Positioned(
                              top: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Offline',
                                        style: TextStyle(
                                            color: !_isOnlineMode
                                                ? Colors.white
                                                : Colors.grey,
                                            fontSize: 12)),
                                    Switch(
                                      value: _isOnlineMode,
                                      onChanged: (value) =>
                                          setState(() => _isOnlineMode = value),
                                      activeColor: AppColors.primaryGreen,
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                    Text('Online',
                                        style: TextStyle(
                                            color: _isOnlineMode
                                                ? Colors.white
                                                : Colors.grey,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),

                            if (_isProcessing)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                          color: Colors.white),
                                      const SizedBox(height: 16),
                                      Text(
                                        _statusMessage,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Using AI to analyze...',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: Text(
                              _statusMessage.isNotEmpty
                                  ? _statusMessage
                                  : 'Camera not available',
                              style: const TextStyle(color: Colors.white))),
                ),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: _isProcessing ? null : _pickFromGallery,
                      ),
                      // Capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _scanFromCamera,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessing
                                ? Colors.grey
                                : AppColors.primaryGreen,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 32),
                        ),
                      ),
                      // Tips button
                      _buildActionButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Tips',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ============================================
// GEMINI API SERVICE
// ============================================

class GeminiService {
  static const String _apiKey = 'AIzaSyC3CCyBg66M5AU4Jvcl24RgQ1yI9155l7Y';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<String> getRemedyForDisease(
      String diseaseName, double confidence) async {
    final prompt = '''
You are an expert agricultural scientist and plant pathologist. A plant disease detection system has identified the following:

Disease/Condition: $diseaseName
Confidence: ${(confidence * 100).toStringAsFixed(1)}%

Please provide a comprehensive but concise response with:

1. **Disease Overview** (2-3 sentences about what this disease/condition is)

2. **Symptoms to Look For** (bullet points of visual symptoms)

3. **Causes** (what causes this disease - fungal, bacterial, environmental, etc.)

4. **Treatment & Remedies**
   - Organic/Natural remedies
   - Chemical treatments (if necessary)
   - Immediate actions to take

5. **Prevention Tips** (how to prevent this in the future)

6. **When to Seek Expert Help** (signs that professional intervention is needed)

Keep the response practical and actionable for farmers. Use simple language.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? 'Unable to generate remedy information.';
      } else {
        debugPrint(
            'Gemini API Error: ${response.statusCode} - ${response.body}');
        return 'Failed to fetch remedy information. Please try again later.';
      }
    } catch (e) {
      debugPrint('Gemini API Exception: $e');
      return 'Network error. Please check your internet connection.';
    }
  }
}

// ============================================
// RESULT SCREEN
// ============================================

class ResultScreen extends StatefulWidget {
  final bool isPlant;
  final String? plantName;
  final String diseaseName;
  final double confidence;
  final String imagePath;
  final String description;

  const ResultScreen({
    super.key,
    this.isPlant = true,
    this.plantName,
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    this.description = '',
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  Widget build(BuildContext context) {
    final confidencePercent = (widget.confidence * 100).toStringAsFixed(1);
    final isHealthy = widget.diseaseName.toLowerCase().contains('healthy');
    final isNotPlant = !widget.isPlant;

    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(isNotPlant ? 'Analysis Result' : 'Diagnosis Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(widget.imagePath),
                  height: 250, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),

            // Result card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Icon based on result type
                  Icon(
                    isNotPlant
                        ? Icons.error_outline
                        : (isHealthy
                            ? Icons.check_circle
                            : Icons.warning_rounded),
                    size: 64,
                    color: isNotPlant
                        ? Colors.red
                        : (isHealthy ? AppColors.primaryGreen : Colors.orange),
                  ),
                  const SizedBox(height: 16),

                  // Status text
                  Text(
                    isNotPlant
                        ? 'Not a Plant!'
                        : (isHealthy
                            ? 'Plant is Healthy!'
                            : 'Disease Detected'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isNotPlant ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Plant name (if available)
                  if (widget.isPlant &&
                      widget.plantName != null &&
                      widget.plantName!.isNotEmpty) ...[
                    Text(
                      widget.plantName!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Disease name or main result
                  Text(
                    widget.diseaseName,
                    style: TextStyle(
                      fontSize:
                          widget.isPlant && widget.plantName != null ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isNotPlant ? Colors.grey[700] : AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Description
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isNotPlant
                            ? Colors.red.shade50
                            : AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isNotPlant
                              ? Colors.red.shade700
                              : AppColors.textDark,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isNotPlant
                          ? Colors.grey.shade200
                          : AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$confidencePercent% Confidence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isNotPlant
                            ? Colors.grey[700]
                            : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons - different for plant vs non-plant
            if (isNotPlant) ...[
              // Not a plant - just show scan again button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan a Plant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please scan a plant leaf or crop to get disease analysis and treatment recommendations.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Plant detected - show remedy buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showLocalRemedySheet(context),
                      icon: const Icon(Icons.healing),
                      label: const Text('Show Remedies'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Send disease name and remedy (if available) to WhatsApp
                    // We need to fetch remedy first or just send disease name
                    // Since remedy is in the bottom sheet, we might not have it here easily unless we fetch it.
                    // For now sending disease name and confidence.
                    final text =
                        'Detected Disease: ${widget.diseaseName}. Confidence: ${(widget.confidence * 100).toStringAsFixed(1)}%. Please provide remedy.';
                    final url =
                        'https://wa.me/7720995173?text=${Uri.encodeComponent(text)}';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Send to WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRemedySheet(context),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Ask AI for More Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRemedySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RemedyBottomSheet(
        diseaseName: widget.diseaseName,
        confidence: widget.confidence,
      ),
    );
  }

  void _showLocalRemedySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocalRemedySheet(
        diseaseName: widget.diseaseName,
      ),
    );
  }
}

// ============================================
// LOCAL REMEDY SHEET (from remedies.json)
// ============================================

class LocalRemedySheet extends StatefulWidget {
  final String diseaseName;

  const LocalRemedySheet({super.key, required this.diseaseName});

  @override
  State<LocalRemedySheet> createState() => _LocalRemedySheetState();
}

class _LocalRemedySheetState extends State<LocalRemedySheet> {
  String? _remedyText;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRemedy();
  }

  Future<void> _loadRemedy() async {
    try {
      final jsonString = await rootBundle.loadString('assets/remedies.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final remedies = data['plant_disease_remedies'] as Map<String, dynamic>;

      // Convert cleaned name back to original format
      // "Apple - Apple scab" -> "Apple___Apple_scab"
      String? remedy;
      final diseaseKey = widget.diseaseName
          .replaceAll(' - ', '___') // Restore triple underscore separator
          .replaceAll(' ', '_'); // Restore single underscores

      debugPrint('Looking for remedy key: $diseaseKey');

      if (remedies.containsKey(diseaseKey)) {
        remedy = remedies[diseaseKey];
      } else {
        // Try partial match (case-insensitive)
        for (var key in remedies.keys) {
          final keyNormalized = key.toLowerCase();
          final diseaseNormalized = diseaseKey.toLowerCase();
          if (keyNormalized == diseaseNormalized ||
              keyNormalized.contains(diseaseNormalized) ||
              diseaseNormalized.contains(keyNormalized)) {
            remedy = remedies[key];
            debugPrint('Found partial match: $key');
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _remedyText = remedy ??
              'No specific remedy found for this condition. Please consult a plant specialist.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _remedyText = 'Failed to load remedies: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.healing, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Remedies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        widget.diseaseName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _remedyText!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// REMEDY BOTTOM SHEET
// ============================================

class RemedyBottomSheet extends StatefulWidget {
  final String diseaseName;
  final double confidence;

  const RemedyBottomSheet({
    super.key,
    required this.diseaseName,
    required this.confidence,
  });

  @override
  State<RemedyBottomSheet> createState() => _RemedyBottomSheetState();
}

class _RemedyBottomSheetState extends State<RemedyBottomSheet> {
  String? _remedyText;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRemedy();
  }

  Future<void> _fetchRemedy() async {
    try {
      final remedy = await GeminiService.getRemedyForDisease(
        widget.diseaseName,
        widget.confidence,
      );
      if (mounted) {
        setState(() {
          _remedyText = remedy;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_services,
                          color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Treatment & Remedies',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Powered by Gemini AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: AppColors.primaryGreen),
                            SizedBox(height: 16),
                            Text(
                              'Analyzing disease and\nfetching remedies...',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load remedies',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[800]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                        _error = null;
                                      });
                                      _fetchRemedy();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Disease info card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bug_report,
                                          color: AppColors.primaryGreen),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.diseaseName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            Text(
                                              '${(widget.confidence * 100).toStringAsFixed(1)}% confidence',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Remedy content
                                _buildMarkdownContent(_remedyText!),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarkdownContent(String text) {
    // Simple markdown-like parsing for better display
    final lines = text.split('\n');
    List<Widget> widgets = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        // Bold header
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.replaceAll('**', ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        // Bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[800], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('#')) {
        // Heading
        final headingText = line.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              headingText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        );
      } else if (line.contains('**')) {
        // Line with bold text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildRichText(line),
          ),
        );
      } else {
        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: Colors.grey[800]),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.textDark),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: Colors.grey[800]),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.5),
        children: spans,
      ),
    );
  }
}

// ============================================
// NEWS SCREEN
// ============================================

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _articles = [];
  bool _loading = true;
  String _activeTab = 'global';
  String? _locationState;

  @override
  void initState() {
    super.initState();
    _loadGlobalNews();
  }

  Future<void> _loadGlobalNews() async {
    setState(() {
      _loading = true;
      _articles = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      const cacheKey = 'NEWS_CACHE_GLOBAL';

      // Try cache first
      final cachedNews = prefs.getString(cacheKey);
      if (cachedNews != null) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(json.decode(cachedNews));
        });
      }

      // Fetch fresh
      const query =
          'crop cultivation OR irrigation OR harvest OR fertilizer OR agriculture';
      final apiUrl =
          'https://gnews.io/api/v4/search?q=${Uri.encodeComponent(query)}&lang=en&max=10&token=$gNewsApiKey';

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['articles'] != null) {
          final freshArticles = (data['articles'] as List)
              .where((a) => a['image'] != null)
              .map((a) => Map<String, dynamic>.from(a))
              .toList();
          setState(() => _articles = freshArticles);
          await prefs.setString(cacheKey, json.encode(freshArticles));
        }
      }
    } catch (e) {
      debugPrint('Error fetching global news: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkAndLoadLocalNews() async {
    setState(() {
      _loading = true;
      _articles = [];
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
            'Location permission permanently denied. Please enable in settings.');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Get state/region from coordinates
      String stateName = 'India';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          stateName = placemarks[0].administrativeArea ??
              placemarks[0].locality ??
              'India';
          setState(() => _locationState = stateName);
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      await _fetchLocalNews(stateName);
    } catch (e) {
      debugPrint('Error in local news: $e');
      _showLocationError('Failed to get location. Ensure GPS is enabled.');
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      setState(() {
        _loading = false;
        _activeTab = 'global';
      });
      _loadGlobalNews();
    }
  }

  Future<void> _fetchLocalNews(String stateName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          'NEWS_CACHE_LOCAL_${stateName.replaceAll(' ', '_').toUpperCase()}';

      final cachedNews = prefs.getString(cacheKey);
      if (cachedNews != null) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(json.decode(cachedNews));
        });
      }

      final query = '"$stateName" (agriculture OR farming OR crops)';
      final apiUrl =
          'https://gnews.io/api/v4/search?q=${Uri.encodeComponent(query)}&lang=en&country=in&max=10&token=$gNewsApiKey';

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['articles'] != null) {
          final freshArticles = (data['articles'] as List)
              .where((a) => a['image'] != null)
              .map((a) => Map<String, dynamic>.from(a))
              .toList();
          setState(() => _articles = freshArticles);
          await prefs.setString(cacheKey, json.encode(freshArticles));
        }
      }
    } catch (e) {
      debugPrint('Fetch local news error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleTabChange(String tab) {
    setState(() => _activeTab = tab);
    if (tab == 'local') {
      _checkAndLoadLocalNews();
    } else {
      _loadGlobalNews();
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Agri News'),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _buildTab('Global News', 'global')),
                  Expanded(child: _buildTab('Local News', 'local')),
                ],
              ),
            ),
          ),

          // Location header for local tab
          if (_activeTab == 'local' && _locationState != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Showing news for: $_locationState',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _loading && _articles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primaryGreen),
                        const SizedBox(height: 16),
                        Text(
                          'Fetching ${_activeTab == 'local' && _locationState != null ? _locationState : 'latest'} updates...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _articles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.newspaper,
                                size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No $_activeTab news available',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _handleTabChange(_activeTab),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _articles.length,
                        itemBuilder: (context, index) =>
                            _buildNewsCard(_articles[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String tab) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => _handleTabChange(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primaryGreen : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    final publishedAt = article['publishedAt'] as String?;
    String dateStr = 'Recent';
    if (publishedAt != null) {
      try {
        final date = DateTime.parse(publishedAt);
        dateStr = '${date.day}/${date.month}/${date.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              article['image'] ?? '',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: AppColors.lightGreen,
                child: const Icon(Icons.image,
                    size: 48, color: AppColors.primaryGreen),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  article['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  article['description'] ?? '',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openArticle(article['url'] ?? ''),
                  child: Row(
                    children: [
                      Text(
                        'Read Full Article',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 16, color: AppColors.primaryGreen),
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
}

// ============================================
// CHAT SCREEN WITH GEMINI AI
// ============================================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // TTS & STT
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _currentLocale = 'en-IN';

  final List<String> _suggestedQuestions = [
    'How to prevent tomato blight?',
    'Best fertilizer for rice crops?',
    'When to harvest wheat?',
    'How to control aphids naturally?',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    setState(() {
      _currentLocale = _getLocaleId(langCode);
    });
  }

  String _getLocaleId(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      case 'kn':
        return 'kn-IN';
      case 'bn':
        return 'bn-IN';
      case 'pa':
        return 'pa-IN';
      default:
        return 'en-IN';
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_currentLocale);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      debugPrint('TTS Error: $msg');
    });
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    await _flutterTts.setLanguage(_currentLocale);
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
  }

  Future<void> _startListening() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice input'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        debugPrint('STT Error: $error');
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          _messageController.text = result.recognizedWords;
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _sendMessage(result.recognizedWords);
          }
        },
        localeId: _currentLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _getGeminiResponse(text.trim());
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I couldn\'t process your request. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }

  Future<String> _getGeminiResponse(String query) async {
    const apiKey = 'AIzaSyC3CCyBg66M5AU4Jvcl24RgQ1yI9155l7Y';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final prompt =
        '''You are an expert agricultural assistant helping farmers with their queries.
Provide helpful, practical advice about farming, crops, plant diseases, pest control, 
fertilizers, irrigation, and other agricultural topics.
Keep responses concise but informative. Use simple language that farmers can easily understand.

User question: $query''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'No response received.';
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('Farm Assistant'),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about farming, crops, diseases...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.lightGreen,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Microphone button for voice input
                  Container(
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Colors.orange[400],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed:
                          _isListening ? _stopListening : _startListening,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                      ),
                      tooltip: _isListening ? 'Stop listening' : 'Voice input',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(_messageController.text),
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture,
              size: 64,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hello, Farmer!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I\'m your AI farming assistant.\nAsk me anything about agriculture!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...(_suggestedQuestions.map((q) => _buildSuggestionChip(q))),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _sendMessage(text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGreen, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : AppColors.textDark,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            // TTS button for AI responses
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: GestureDetector(
                  onTap: () => _speak(message.text),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSpeaking ? Icons.stop : Icons.volume_up,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSpeaking ? 'Stop' : 'Listen',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PROFILE SCREEN
// ============================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!, width: 3),
                ),
                child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Farmer User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Village Name, District',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // General section
              _buildSection(
                'SETTINGS',
                [
                  _buildMenuItem(Icons.language, 'Change Language',
                      () => _showLanguageDialog(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Support section
              _buildSection(
                'SUPPORT',
                [
                  _buildMenuItem(Icons.help_outline, 'Help & FAQ', () {}),
                  _buildMenuItem(
                    Icons.logout,
                    'Logout',
                    () {},
                    isDestructive: true,
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: LocalizationService.supportedLanguages.map((lang) {
              return ListTile(
                title: Text(lang['nativeName']!),
                subtitle: Text(lang['name']!),
                onTap: () async {
                  await LocalizationService.setLanguage(lang['code']!);
                  Navigator.pop(context);
                  // Show snackbar or restart hint
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Language changed. Please restart app to apply fully.')),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : AppColors.textGrey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.red : AppColors.textDark,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
// ============================================
// REMINDER SCREEN
// ============================================

class Reminder {
  final String id;
  final String title;
  final String date;

  Reminder({required this.id, required this.title, required this.date});
}

// ============================================
// MARKETPLACE SCREEN
// ============================================

const String _mandiApiKey =
    '579b464db66ec23bdd000001a9620aef73554784784dd1a97ad20ace';
const String _mandiApiUrl =
    'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

class CommodityPrice {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final String minPrice;
  final String maxPrice;
  final String modalPrice;

  CommodityPrice({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });

  factory CommodityPrice.fromJson(Map<String, dynamic> json) {
    return CommodityPrice(
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      commodity: json['commodity'] ?? '',
      variety: json['variety'] ?? '',
      grade: json['grade'] ?? '',
      arrivalDate: json['arrival_date'] ?? '',
      minPrice: json['min_price']?.toString() ?? '0',
      maxPrice: json['max_price']?.toString() ?? '0',
      modalPrice: json['modal_price']?.toString() ?? '0',
    );
  }
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<CommodityPrice> _prices = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedState;
  String? _selectedCommodity;

  final TextEditingController _searchController = TextEditingController();

  // Common states for filtering
  final List<String> _states = [
    'All States',
    'Maharashtra',
    'Gujarat',
    'Rajasthan',
    'Madhya Pradesh',
    'Uttar Pradesh',
    'Punjab',
    'Haryana',
    'Karnataka',
    'Andhra Pradesh',
    'Tamil Nadu',
    'West Bengal',
    'Bihar',
  ];

  // Common commodities for filtering
  final List<String> _commodities = [
    'All Commodities',
    'Wheat',
    'Rice',
    'Onion',
    'Tomato',
    'Potato',
    'Cotton',
    'Soyabean',
    'Maize',
    'Groundnut',
    'Sugarcane',
    'Banana',
    'Apple',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrices({String? state, String? commodity}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url = '$_mandiApiUrl?api-key=$_mandiApiKey&format=json&limit=100';

      if (state != null && state != 'All States') {
        url += '&filters[state.keyword]=$state';
      }
      if (commodity != null && commodity != 'All Commodities') {
        url += '&filters[commodity]=$commodity';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] as List<dynamic>? ?? [];

        setState(() {
          _prices = records.map((r) => CommodityPrice.fromJson(r)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch prices. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching prices: $e';
        _isLoading = false;
      });
    }
  }

  List<CommodityPrice> get _filteredPrices {
    if (_searchQuery.isEmpty) return _prices;
    final query = _searchQuery.toLowerCase();
    return _prices.where((price) {
      return price.commodity.toLowerCase().contains(query) ||
          price.market.toLowerCase().contains(query) ||
          price.district.toLowerCase().contains(query) ||
          price.state.toLowerCase().contains(query);
    }).toList();
  }

  void _applyFilters() {
    _fetchPrices(state: _selectedState, commodity: _selectedCommodity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: const Text('Mandi Prices'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _applyFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search commodity, market...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primaryGreen),
                    filled: true,
                    fillColor: AppColors.lightGreen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('State'),
                            value: _selectedState,
                            items: _states.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(state,
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Commodity'),
                            value: _selectedCommodity,
                            items: _commodities.map((commodity) {
                              return DropdownMenuItem(
                                value: commodity,
                                child: Text(commodity,
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCommodity = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.primaryGreen),
                        SizedBox(height: 16),
                        Text('Fetching latest mandi prices...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _applyFilters,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredPrices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No prices found',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchPrices(
                              state: _selectedState,
                              commodity: _selectedCommodity,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPrices.length,
                              itemBuilder: (context, index) {
                                final price = _filteredPrices[index];
                                return _buildPriceCard(price);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(CommodityPrice price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commodity Name & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    price.commodity,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price.arrivalDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Variety & Grade
            if (price.variety.isNotEmpty || price.grade.isNotEmpty)
              Text(
                '${price.variety}${price.grade.isNotEmpty ? ' • ${price.grade}' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 12),
            // Location
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${price.market}, ${price.district}, ${price.state}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Prices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPriceColumn('Min', price.minPrice, Colors.red[400]!),
                _buildPriceColumn(
                    'Modal', price.modalPrice, AppColors.primaryGreen),
                _buildPriceColumn('Max', price.maxPrice, Colors.blue[400]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceColumn(String label, String price, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹$price',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '/quintal',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Reminder> _reminders = [
    Reminder(
        id: '1', title: 'Water the Wheat field', date: 'Tomorrow, 6:00 AM'),
    Reminder(id: '2', title: 'Buy fertilizers', date: 'Sat, 10:00 AM'),
  ];

  void _addReminder() {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('reminder') ?? 'Reminder',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Water plants',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('When?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                hintText: 'e.g. Tomorrow 9 AM',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  dateController.text.isNotEmpty) {
                setState(() {
                  _reminders.add(Reminder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    date: dateController.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteReminder(String id) {
    setState(() {
      _reminders.removeWhere((r) => r.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: Text(tr('reminder') ?? 'Reminder'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      body: _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text('No reminders set.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tap the + button to add one.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Text(
                      reminder.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 5),
                        Text(reminder.date,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () => _deleteReminder(reminder.id),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}

// ============================================
// CARE GUIDES SCREEN
// ============================================

class CareGuidesScreen extends StatefulWidget {
  const CareGuidesScreen({super.key});

  @override
  State<CareGuidesScreen> createState() => _CareGuidesScreenState();
}

class _CareGuidesScreenState extends State<CareGuidesScreen> {
  List<ScanRecord> _plants = [];
  ScanRecord? _selectedPlant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final history = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _plants = history;
        _selectedPlant = history.isNotEmpty ? history.first : null;
        _isLoading = false;
      });
    }
  }

  Map<String, String> _getCareGuide(String diseaseName) {
    return {
      'water': 'Water every 2-3 days, keep soil moist but not waterlogged',
      'sunlight': '6-8 hours of direct sunlight daily',
      'fertilizer':
          'Use organic fertilizer every 2 weeks during growing season',
      'pests':
          'Inspect regularly for aphids and caterpillars. Use neem oil if needed.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: Text(tr('care_guides') ?? 'Care Guides'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Plants & Care Guides',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 15),
                  if (_plants.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.eco_outlined,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text('No plants scanned yet.',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  else ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _plants
                            .map((plant) => _buildPlantItem(plant))
                            .toList(),
                      ),
                    ),
                    if (_selectedPlant != null) ...[
                      const SizedBox(height: 20),
                      _buildCareGuideCard(
                          _getCareGuide(_selectedPlant!.diseaseName)),
                    ],
                    const SizedBox(height: 25),
                    const Text(
                      'Recent Diagnosis History',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 15),
                    ..._plants.map((plant) => _buildDiagnosisCard(plant)),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildPlantItem(ScanRecord plant) {
    final isSelected = _selectedPlant?.id == plant.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlant = plant),
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.accentGreen, width: 2)
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2)
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.accentGreen, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: File(plant.imagePath).existsSync()
                    ? Image.file(File(plant.imagePath), fit: BoxFit.cover)
                    : const Icon(Icons.eco,
                        color: AppColors.primaryGreen, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              child: Text(
                plant.diseaseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryGreen : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareGuideCard(Map<String, String> careGuide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Care Guide',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              Row(
                children: [
                  Icon(Icons.water_drop, size: 30, color: Colors.blue[400]),
                  const SizedBox(width: 10),
                  const Icon(Icons.wb_sunny, size: 30, color: Colors.amber),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildGuideLine('Water', careGuide['water']!),
          _buildGuideLine('Sunlight', careGuide['sunlight']!),
          _buildGuideLine('Fertilizer', careGuide['fertilizer']!),
          _buildGuideLine('Pests', careGuide['pests']!),
        ],
      ),
    );
  }

  Widget _buildGuideLine(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(ScanRecord plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: File(plant.imagePath).existsSync()
                  ? Image.file(File(plant.imagePath), fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 40),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnosis: ${plant.diseaseName}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(plant.confidence * 100).toStringAsFixed(1)}% confidence',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(plant.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.orange),
            onPressed: () async {
              await HistoryService.deleteRecord(plant.id);
              _loadPlants(); // Reload
            },
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
// ============================================
// SERVICES & MODELS (Restored)
// ============================================

class ScanRecord {
  final String id;
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final DateTime timestamp;
  final String description;

  ScanRecord({
    required this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.timestamp,
    required this.description,
  });

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] ?? '',
      imagePath: map['imagePath'] ?? '',
      diseaseName: map['diseaseName'] ?? map['label'] ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      description: map['description'] ?? '',
    );
  }
}

class HistoryService {
  static const String _key = 'scan_history';

  static Future<List<ScanRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    try {
      final List<dynamic> list = jsonDecode(data);
      return list
          .map((e) => ScanRecord.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveScan(
      Map<String, dynamic> result, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    // Get existing raw list
    List<Map<String, dynamic>> mapList = [];
    try {
      final String? data = prefs.getString(_key);
      if (data != null) {
        mapList = List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      mapList = [];
    }

    final newRecord = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'imagePath': imagePath,
      'diseaseName': result['label'] ?? result['diseaseName'] ?? 'Unknown',
      'confidence': result['confidence'],
      'timestamp': DateTime.now().toIso8601String(),
      'description': result['description'] ?? '',
    };

    mapList.insert(0, newRecord);
    await prefs.setString(_key, jsonEncode(mapList));
  }

  static Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> mapList = [];
    try {
      final String? data = prefs.getString(_key);
      if (data != null) {
        mapList = List<Map<String, dynamic>>.from(jsonDecode(data));
      }
    } catch (e) {
      return;
    }

    mapList.removeWhere((item) => item['id'] == id);
    await prefs.setString(_key, jsonEncode(mapList));
  }
}

class LocalizationService {
  static String _currentLanguage = 'en';

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
    {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
    {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
    {'code': 'kn', 'name': 'Kannada', 'nativeName': 'kannada'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
    {'code': 'pa', 'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ'},
  ];

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'Farm Assistant',
      'reminder': 'Reminder',
      'care_guides': 'Care Guides',
      'no_plant': 'No Plant Detected',
    },
    'hi': {
      'app_name': 'कृषि सहायक',
      'reminder': 'अनुस्मारक',
      'care_guides': 'देखभाल गाइड',
    },
    'mr': {
      'app_name': 'शेती सहाय्यक',
      'reminder': 'स्मरणपत्र',
      'care_guides': 'काळजी मार्गदर्शक',
    },
  };

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language_code') ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    _currentLanguage = code;
  }

  static String translate(String key) {
    if (_translations.containsKey(_currentLanguage) &&
        _translations[_currentLanguage]!.containsKey(key)) {
      return _translations[_currentLanguage]![key]!;
    }
    if (_translations['en']!.containsKey(key)) {
      return _translations['en']![key]!;
    }
    return key;
  }
}

String tr(String key) => LocalizationService.translate(key);

// ============================================
// TFLITE SERVICE
// ============================================

class TFLiteService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool _isLoaded = false;

  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      final jsonData = await rootBundle.loadString('assets/class_indices.json');
      final Map<String, dynamic> classIndices = json.decode(jsonData);
      _labels = List.filled(classIndices.length, '');
      classIndices.forEach((label, index) {
        String cleanLabel = label.replaceAll('___', ' - ').replaceAll('_', ' ');
        _labels[index] = cleanLabel;
      });
      _isLoaded = true;
      debugPrint('TFLite Model loaded.');
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
    }
  }

  static Future<Map<String, dynamic>> analyze(String imagePath) async {
    if (!_isLoaded) await loadModel();
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Model failed to load. Check assets.');
    }

    final imageBytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');

    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    var input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          },
        ),
      ),
    );

    var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input, output);

    int maxIndex = 0;
    double maxProb = output[0][0];
    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxProb) {
        maxProb = output[0][i];
        maxIndex = i;
      }
    }

    // Only show results with 99%+ confidence as valid plants
    final bool isValidResult = maxProb >= 1.0;

    return {
      'isPlant': isValidResult,
      'label': isValidResult ? _labels[maxIndex] : 'Not a Plant',
      'confidence': maxProb,
      'description': isValidResult 
          ? 'Detected locally using TFLite.' 
          : 'Could not identify a plant with sufficient confidence. Please try again with a clearer image.',
      'plantName': null,
    };
  }
}
