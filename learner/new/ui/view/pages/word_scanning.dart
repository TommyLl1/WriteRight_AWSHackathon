import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/word_scanning.dart';
import 'package:writeright/new/data/models/wrong_words.dart';
import 'package:image_picker/image_picker.dart';

class GetPhotoPage extends StatelessWidget {
  const GetPhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GetPhotoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('錯字偵探'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          onPressed: () {
            context.go('/home'); // Navigate back to the home page
          },
        ),
      ),
      body: viewModel.receivedTextDetectionResponse
          ? _buildResultView(context, viewModel)
          : _buildScanningView(context, viewModel),
    );
  }

  Widget _buildScanningView(BuildContext context, GetPhotoViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the uploaded image scaled to fit the box
          Container(
            height: 300, // Fixed height for the box
            width: double.infinity, // Full width of the screen
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: viewModel.webImageBytes != null
                  ? FittedBox(
                      fit: BoxFit
                          .contain, // Ensure the image fits within the box
                      child: Image.memory(
                        viewModel.webImageBytes!,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '圖片載入失敗\n可能是圖片過大',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : viewModel.imageFile != null
                  ? FittedBox(
                      fit: BoxFit
                          .contain, // Ensure the image fits within the box
                      child: Image.file(
                        File(viewModel.imageFile!.path),
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '圖片載入失敗\n可能是圖片過大',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text(
                        '請選擇圖片',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => viewModel.selectImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('相機'),
              ),
              ElevatedButton.icon(
                onPressed: () => viewModel.selectImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('相冊'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Column(
            children: [
              if (viewModel.isScanning) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text(
                  '正在掃描圖片... （預計時間：兩分鐘）',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: viewModel.isImageSelected
                      ? () {
                          try {
                            viewModel.startScanning();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Scanning in ${viewModel.selectedScanMode}...',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      : null,
                  child: const Text('掃描圖片'),
                ),
              ],
              const SizedBox(height: 20),

              // Display error message if there's an error
              if (viewModel.isError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage ?? '發生未知錯誤',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, GetPhotoViewModel viewModel) {
    final notFoundWords = viewModel.textDetectionResponse?.notFound ?? [];
    final wrongWords = viewModel.textDetectionResponse?.data ?? [];

    // Convert both lists to WrongWordDisplayable
    final List<WrongWordDisplayable> allWrongWords = [
      ...wrongWords.cast<WrongWordDisplayable>(),
      ...notFoundWords.cast<WrongWordDisplayable>(),
    ];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            '偵測結果',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        // Add legend for different colors
        if (allWrongWords.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('錯字', const Color(0xFF012B44)),
                _buildLegendItem('無法識別', const Color(0xFF8B0000)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: allWrongWords.isNotEmpty
              ? ListView.builder(
                  itemCount: allWrongWords.length,
                  itemBuilder: (context, index) {
                    final word = allWrongWords[index];
                    return WrongScannedWordCard(word: word);
                  },
                )
              : const Center(
                  child: Text(
                    '全部正確！',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        Container(
          margin: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              context.go('/home'); // Navigate back to the home page
            },
            child: const Text('返回主頁'),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class WrongScannedWordCard extends StatelessWidget {
  final WrongWordDisplayable word;

  const WrongScannedWordCard({required this.word, super.key});

  Color get backgroundColor {
    if (word.isInDatabase) {
      return const Color(0xFF012B44); // Is valid word in database
    }
    // DB not found, usually means simplified chinese, or chars above primary school level
    return const Color(0xFF8B0000);
  }

  Color get textColor {
    return Colors.white70; // All text is white for now
  }

  // String get statusText {
  //   if (word.isInDatabase) {
  //     return '歷史錯誤';
  //   } else if (!word.isCorrect) {
  //     return '新發現錯誤';
  //   } else {
  //     return '正確';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Display the wrong word's image or placeholder
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: word.wrongImageUrl != null
                  ? Image.network(
                      word.wrongImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading image: $error');
                        return _buildPlaceholder();
                      },
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 16),
            // Display the word information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.displayCharacter,
                    style: TextStyle(
                      fontSize: 20,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (word.reasoning != null && word.reasoning!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.reasoning!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        word.displayCharacter,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
