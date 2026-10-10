import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../models/photo_item.dart';
import '../services/hangout_repository.dart';
import '../services/media_storage_service.dart';
import '../widgets/creme_pills.dart';

class PhotoScanModal extends StatefulWidget {
  final String hangoutId;

  const PhotoScanModal({super.key, required this.hangoutId});

  @override
  State<PhotoScanModal> createState() => _PhotoScanModalState();
}

class _PhotoScanModalState extends State<PhotoScanModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  bool _isProcessing = false;
  PhotoItem? _scannedPhoto;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final file = await MediaStorageService.instance.pickFromGallery();
    if (file == null) return;
    await _setPickedFile(file);
  }

  Future<void> _pickFromCamera() async {
    final file = await MediaStorageService.instance.pickFromCamera();
    if (file == null) return;
    await _setPickedFile(file);
  }

  Future<void> _setPickedFile(XFile file) async {
    final path = await MediaStorageService.instance.persistImage(file);
    if (!mounted || path == null) return;
    setState(() {
      _localImagePath = path;
      _scannedPhoto = null;
    });
  }

  Future<void> _runFaceScan() async {
    final path = _localImagePath;
    if (path == null) return;

    setState(() {
      _isProcessing = true;
      _scannedPhoto = null;
    });

    final bytes = await File(path).length();
    final photo = await HangoutRepository.instance.addPhotoWithFaceScan(
      hangoutId: widget.hangoutId,
      imageUrl: path,
      originalSizeBytes: bytes,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _scannedPhoto = photo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.viewInsets.bottom;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, topInset > 40 ? 24 : 36, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scanning your photo…',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 210,
                  child: _localImagePath == null
                      ? Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Text(
                              'Pick a photo to scan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : (_isProcessing
                          ? AnimatedBuilder(
                              animation: _scannerController,
                              builder: (context, _) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(_localImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top:
                                          18 + 174 * _scannerController.value,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 2.5,
                                        color: AppColors.amber,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Image.file(
                              File(_localImagePath!),
                              fit: BoxFit.cover,
                            )),
                ),
              ),

              const SizedBox(height: 20),

              if (_localImagePath == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: SoftPill(
                        'Camera',
                        icon: Icons.photo_camera_outlined,
                        onTap: _pickFromCamera,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SoftPill(
                        'Gallery',
                        icon: Icons.photo_library_outlined,
                        onTap: _pickFromGallery,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SoftPill(
                    'Scan faces',
                    icon: Icons.auto_awesome,
                    filled: true,
                    onTap: null,
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SoftPill(
                        'Pick another',
                        icon: Icons.photo_library_outlined,
                        onTap: _isProcessing ? null : _pickFromGallery,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SoftPill(
                        'Scan faces',
                        icon: Icons.auto_awesome,
                        filled: true,
                        onTap: _isProcessing ? null : _runFaceScan,
                      ),
                    ),
                  ],
                ),
              ],

              if (_scannedPhoto != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scannedPhoto!.detectedAttendeeIds.isEmpty
                            ? 'No faces matched — photo is public in the share'
                            : '${_scannedPhoto!.detectedAttendeeIds.length} people recognised — waiting for consent',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
