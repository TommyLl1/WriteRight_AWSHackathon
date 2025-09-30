// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'utils/logger.dart';

// class GetPhotoPage extends StatefulWidget {
//   const GetPhotoPage({super.key});

//   @override
//   _GetPhotoPageState createState() => _GetPhotoPageState();
// }

// class _GetPhotoPageState extends State<GetPhotoPage> {
//   XFile? _imageFile;
//   Uint8List? _webImageBytes;
//   final ImagePicker _picker = ImagePicker();
//   String _scanMode = 'Mode 1'; // Default scan mode

//   Future<bool> _checkStoragePermission() async {
//     // Skip permission check on web platform
//     if (kIsWeb) return true;

//     if (Platform.isAndroid) {
//       final androidInfo = await DeviceInfoPlugin().androidInfo;
//       if (androidInfo.version.sdkInt < 29) {
//         final status = await Permission.storage.status;
//         if (status.isDenied) {
//           final result = await Permission.storage.request();
//           return result.isGranted;
//         }
//         return status.isGranted;
//       }
//     }
//     return true; // No permission needed for API 29+ or iOS
//   }

//   Future<void> _getImage(ImageSource source) async {
//     try {
//       // Only check storage permission for gallery access on older Android versions
//       if (source == ImageSource.gallery) {
//         final hasPermission = await _checkStoragePermission();
//         if (!hasPermission) {
//           if (!mounted) return;
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content:
//                     Text('Storage permission is required to access gallery')),
//           );
//           return;
//         }
//       }
//       final pickedFile = await _picker.pickImage(source: source);
//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = pickedFile;
//         });

//         // For web platform, also store the bytes
//         if (kIsWeb) {
//           final bytes = await pickedFile.readAsBytes();
//           setState(() {
//             _webImageBytes = bytes;
//           });
//         }
//       }
//     } catch (e) {
//       AppLogger.error('Error picking image', e);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to pick image')),
//       );
//     }
//   }

//   void _startScanning() {
//     if (_imageFile == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(
//           const SnackBar(content: Text('Please select an image first.')));
//       return;
//     } // Replace this with your actual scanning logic
//     AppLogger.userAction('Starting scan', context: {'mode': _scanMode});
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text('Scanning in $_scanMode...')));
//   }

//   Widget _buildImageWidget() {
//     // Calculate responsive box size based on screen dimensions
//     final screenSize = MediaQuery.of(context).size;
//     final smallestEdge = screenSize.width < screenSize.height
//         ? screenSize.width
//         : screenSize.height;
//     final boxSize = (smallestEdge * 0.7)
//         .clamp(200.0, 400.0); // 70% of smallest edge, min 200, max 400

//     if (_imageFile == null) {
//       return Container(
//         width: boxSize,
//         height: boxSize,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           border: Border.all(color: Colors.grey.shade400, width: 2),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.broken_image,
//               size: boxSize * 0.25, // Scale icon relative to box size
//               color: Colors.grey.shade500,
//             ),
//             SizedBox(height: boxSize * 0.05),
//             Text(
//               'No image selected',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: (boxSize * 0.05).clamp(14.0, 18.0),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Container with responsive size and proper image scaling
//     return Container(
//       width: boxSize,
//       height: boxSize,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400, width: 2),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(
//             6), // Slightly smaller radius for inner content
//         child: _buildResponsiveImage(boxSize),
//       ),
//     );
//   }

//   Widget _buildResponsiveImage(double boxSize) {
//     // For web platform, use Image.memory with the stored bytes
//     if (kIsWeb && _webImageBytes != null) {
//       return Image.memory(
//         _webImageBytes!,
//         width: boxSize,
//         height: boxSize,
//         fit:
//             BoxFit.contain, // Changed to contain to show full image scaled down
//       );
//     }

//     // For mobile platforms, use Image.file with File path
//     if (!kIsWeb) {
//       return Image.file(
//         File(_imageFile!.path),
//         width: boxSize,
//         height: boxSize,
//         fit:
//             BoxFit.contain, // Changed to contain to show full image scaled down
//       );
//     }

//     // Fallback for web if bytes are not available yet
//     return FutureBuilder<Uint8List>(
//       future: _imageFile!.readAsBytes(),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           return Image.memory(
//             snapshot.data!,
//             width: boxSize,
//             height: boxSize,
//             fit: BoxFit
//                 .contain, // Changed to contain to show full image scaled down
//           );
//         } else if (snapshot.hasError) {
//           return const Text('Error loading image');
//         } else {
//           return const CircularProgressIndicator();
//         }
//       },
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('錯字偵探')),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               _buildImageWidget(),
//               SizedBox(height: 20),
//               // Hint text when no image is selected
//               if (_imageFile == null && _webImageBytes == null)
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   margin: EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.blue.shade200),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info_outline, color: Colors.blue.shade600),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           '請選擇一張圖片來開始掃描',
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               // Camera and Gallery buttons side by side
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.only(right: 8.0),
//                       child: ElevatedButton.icon(
//                         onPressed: () => _getImage(ImageSource.camera),
//                         icon: Icon(Icons.camera_alt),
//                         label: Text('相機'),
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.only(left: 8.0),
//                       child: ElevatedButton.icon(
//                         onPressed: () => _getImage(ImageSource.gallery),
//                         icon: const Icon(Icons.photo_library),
//                         label: const Text('相冊'),
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//               // Dropdown for scan mode selection with label on the left
//               Row(
//                 children: [
//                   const Text(
//                     '掃描模式: ',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(horizontal: 12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<String>(
//                           value: _scanMode,
//                           isExpanded: true,
//                           items: const [
//                             DropdownMenuItem(
//                               value: 'Mode 1',
//                               child: Text('格仔紙'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'Mode 2',
//                               child: Text('通用'),
//                             ),
//                           ],
//                           onChanged: (String? newValue) {
//                             setState(() {
//                               _scanMode = newValue!;
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 40),
//               // Big Submit button with dynamic color
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _startScanning,
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 16),
//                     textStyle: TextStyle(fontSize: 18),
//                     backgroundColor:
//                         (_imageFile != null || _webImageBytes != null)
//                             ? Colors.green
//                             : null,
//                     foregroundColor:
//                         (_imageFile != null || _webImageBytes != null)
//                             ? Colors.white
//                             : null,
//                   ),
//                   child: Text(
//                     (_imageFile != null || _webImageBytes != null)
//                         ? '掃描圖片'
//                         : '請先選擇圖片',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
