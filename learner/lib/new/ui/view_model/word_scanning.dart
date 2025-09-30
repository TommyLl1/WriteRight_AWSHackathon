import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:writeright/new/data/services/permission.dart';
import 'package:writeright/new/data/services/wrong_character.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/utils/exceptions.dart';
import 'package:writeright/new/data/models/wrong_words.dart';

class GetPhotoViewModel extends ChangeNotifier {
  final PermissionService scanningPermissionService;
  final WrongCharacterService wrongCharacterService;
  GetPhotoViewModel(
    this.scanningPermissionService,
    this.wrongCharacterService,
  ) {
    AppLogger.debug('GetPhotoViewModel initialized');
  }

  XFile? _imageFile;
  Uint8List? _webImageBytes;
  String _selectedScanMode = "Mode 1"; // Default scan mode

  XFile? get imageFile => _imageFile;
  Uint8List? get webImageBytes => _webImageBytes;
  String get selectedScanMode => _selectedScanMode;

  bool get isImageSelected => _imageFile != null || _webImageBytes != null;

  bool _isScanning = false; // Placeholder for scanning state
  bool get isScanning => _isScanning;

  TextDetectionResponse? _textDetectionResponse;
  TextDetectionResponse? get textDetectionResponse => _textDetectionResponse;
  bool get receivedTextDetectionResponse => _textDetectionResponse != null;

  String _errorMessage = '請稍後再試。';
  String? get errorMessage => _errorMessage;
  bool _isError = false;
  bool get isError => _isError;

  Future<void> selectImage(ImageSource source) async {
    final int maxFileSize = 6 * 1024 * 1024; // 10MB limit for web
    try {
      final XFile? pickedFile = await scanningPermissionService.getImage(
        source,
      );
      if (pickedFile != null) {
        _imageFile = pickedFile;

        // Check file size before processing
        final fileSize = await pickedFile.length();
        AppLogger.debug('Selected image size: ${fileSize / (1024 * 1024)} MB');

        if (kIsWeb) {
          // For web, check if file is too large before reading bytes
          if (fileSize > maxFileSize) {
            AppLogger.warning(
              'Image too large for web platform: ${fileSize / (1024 * 1024)} MB',
            );
            _isError = true;
            _errorMessage = '圖片過大，請選擇較小的圖片';
            notifyListeners();
            return;
          }

          try {
            _webImageBytes = await pickedFile.readAsBytes();
            AppLogger.debug('Successfully loaded image bytes for web');
          } catch (e) {
            AppLogger.error('Failed to read image bytes for web', e);
            _isError = true;
            _errorMessage = '圖片載入失敗，可能是圖片過大或格式不支援';
            notifyListeners();
            return;
          }
        }

        // Clear any previous errors
        _isError = false;
        _errorMessage = '請稍後再試。';
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error selecting image', e);
      _isError = true;
      _errorMessage = '選擇圖片失敗，請重試';
      notifyListeners();
      throw Exception('Failed to pick image');
    }
  }

  void setScanMode(String mode) {
    _selectedScanMode = mode;
    notifyListeners();
  }

  void startScanning() {
    if (!isImageSelected) {
      throw Exception('Please select an image first');
    }
    if (_isScanning) {
      AppLogger.warning('Scanning is already in progress');
      return;
    }
    _isError = false; // Reset error state
    _errorMessage = '請稍後再試。'; // Reset error message
    _textDetectionResponse = null; // Reset previous response
    _isScanning = true;
    notifyListeners();

    wrongCharacterService
        .uploadAndScan(imageFile: _imageFile, webImageBytes: _webImageBytes)
        .then((response) {
          AppLogger.debug('TextDetection completed: ${response.toString()}');
          _textDetectionResponse = response;
          _isScanning = false;
          notifyListeners();
        })
        .catchError((error) {
          AppLogger.error('Error during scanning', error);
          _isError = true;
          _isScanning = false;

          // Handle specific error types
          if (error is ServerUnavailableException) {
            _errorMessage = '伺服器暫時無法使用，請稍後再試';
          } else if (error is ServerErrorException) {
            _errorMessage = '伺服器處理請求時發生錯誤，請稍後再試';
          } else if (error is PayloadTooLargeException) {
            _errorMessage = '圖片過大，請裁切或壓縮圖片，或選擇較小的圖片';
          } else if (error is InvalidInputException) {
            _errorMessage = '圖片中未找到錯字，請嘗試其他圖片';
          } else if (error is NetworkException) {
            _errorMessage = error.message;
          } else if (error is HttpException) {
            switch (error.statusCode) {
              case 413:
                _errorMessage = '圖片過大，請裁切或壓縮圖片，或選擇較小的圖片';
                break;
              case 502:
              case 503:
                _errorMessage = '伺服器暫時無法使用，請稍後再試';
                break;
              case 500:
                _errorMessage = '伺服器處理請求時發生錯誤';
                break;
              case 422:
                _errorMessage = '圖片中未找到錯字，請嘗試其他圖片';
                break;
              default:
                _errorMessage = '掃描失敗，請稍後再試 (錯誤代碼: ${error.statusCode})';
            }
          } else {
            _errorMessage = '掃描失敗，請稍後再試';
          }

          notifyListeners();
        });
  }
}
