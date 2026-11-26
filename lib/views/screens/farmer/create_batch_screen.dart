import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../models/batch_model.dart';
import '../../../providers/traceability_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/firebase_service.dart';

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  Uint8List? _imageBytes;
  XFile? _selectedImage;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();
  String _certType = 'VietGAP';
  late TextEditingController _certNumberController;
  late TextEditingController _inspectorController;
  late TextEditingController _testResultsController;
  late TextEditingController _yieldController;

  @override
  void initState() {
    super.initState();
    _certNumberController = TextEditingController(text: 'VietGAP-TT-2026-0922');
    _inspectorController = TextEditingController(
      text: 'KS. Lê Văn Khoa (Chi cục BVTV)',
    );
    _testResultsController = TextEditingController(
      text: 'Dư lượng BVTV: 0.0 mg/kg | Đạt chuẩn an toàn sinh học VietGAP',
    );
    _yieldController = TextEditingController(text: '1000');
  }

  @override
  void dispose() {
    _certNumberController.dispose();
    _inspectorController.dispose();
    _testResultsController.dispose();
    _yieldController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final traceProv = Provider.of<TraceabilityProvider>(context, listen: false);

    var product = prodProv.products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => prodProv.products.first,
    );

    final now = DateTime.now();
    final batchCode =
        'BATCH-${product.id.replaceAll('PROD-', '')}-${now.year}-${const Uuid().v4().substring(0, 4).toUpperCase()}';
    var imageUrl = product.imageUrl;

    if (_imageBytes != null) {
      if (!FirebaseService.isInitialized) {
        _showError('Chưa kết nối Firebase. Không thể upload ảnh sản phẩm.');
        setState(() => _isSaving = false);
        return;
      }
      imageUrl =
          await FirebaseService.uploadImageBytes(
            storagePath: 'products/${product.id}.jpg',
            bytes: _imageBytes!,
          ) ??
          '';
      if (imageUrl.isEmpty) {
        _showError('Upload ảnh thất bại. Vui lòng kiểm tra Firebase Storage.');
        setState(() => _isSaving = false);
        return;
      }
      product = product.copyWith(imageUrl: imageUrl);
      await prodProv.updateProduct(product);
    }

    final newBatch = BatchModel(
      id: batchCode,
      productId: product.id,
      productName: product.name,
      imageUrl: imageUrl,
      farmId: product.farmId,
      farmName: product.farmName,
      farmLocation: product.region,
      harvestDate: '${now.day}/${now.month}/${now.year}',
      expiryDate: '${now.day + 14}/${now.month}/${now.year}',
      certType: _certType,
      certNumber: _certNumberController.text.trim(),
      certAuthority: 'Chi cục Trồng trọt & Bảo vệ Thực vật',
      inspectorName: _inspectorController.text.trim(),
      testResults: _testResultsController.text.trim(),
      totalYieldKg: int.tryParse(_yieldController.text.trim()) ?? 500,
      timeline: [
        TimelineStepModel(
          title: 'Gieo hạt và cấy mô sinh học',
          description: 'Xuống giống tại vườn ươm tiêu chuẩn công nghệ cao.',
          timestamp: '${now.day - 45}/${now.month}/${now.year} 08:00',
          location: product.region,
          responsiblePerson: 'Ban Quản trị Vườn',
        ),
        TimelineStepModel(
          title: 'Kiểm tra dư lượng BVTV tại đồng',
          description: _testResultsController.text.trim(),
          timestamp: '${now.day - 2}/${now.month}/${now.year} 10:30',
          location: 'Phòng Lab Kiểm định Chất lượng',
          responsiblePerson: _inspectorController.text.trim(),
        ),
        TimelineStepModel(
          title: 'Thu hoạch và sinh mã QR động',
          description:
              'Thu hoạch mẻ hàng tươi ngon và in tem truy xuất điện tử.',
          timestamp: '${now.day}/${now.month}/${now.year} 06:00',
          location: product.farmName,
          responsiblePerson: 'Tổ trưởng thu hái',
        ),
      ],
    );

    await traceProv.addNewBatch(newBatch);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo thành công lô hàng mới: $batchCode!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImage = picked;
      _imageBytes = bytes;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Widget _buildImagePicker(String? currentImageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh sản phẩm / lô hàng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 190,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_imageBytes != null)
                  Image.memory(_imageBytes!, fit: BoxFit.cover)
                else if (currentImageUrl != null && currentImageUrl.isNotEmpty)
                  Image.network(
                    currentImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emptyImageState(),
                  )
                else
                  _emptyImageState(),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedImage == null ? 'Chọn ảnh' : 'Đổi ảnh',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
        ),
        const SizedBox(height: 5),
        const Text(
          'Ảnh sẽ được upload vào Firebase Storage và gắn với sản phẩm này.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _emptyImageState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.primary,
          size: 42,
        ),
        SizedBox(height: 8),
        Text(
          'Chưa có ảnh sản phẩm',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);

    if (_selectedProductId == null && prodProv.products.isNotEmpty) {
      _selectedProductId = prodProv.products.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo lô hàng mới & Sinh tem QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin nông sản & Mùa vụ thu hoạch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Chọn nông sản thu hoạch',
                ),
                items: prodProv.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.name} (${p.farmName})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedProductId = val),
              ),
              const SizedBox(height: 18),
              _buildImagePicker(
                _selectedProductId == null
                    ? null
                    : prodProv.getProductById(_selectedProductId!)?.imageUrl,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _certType,
                decoration: const InputDecoration(
                  labelText: 'Tiêu chuẩn chất lượng',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'VietGAP',
                    child: Text('VietGAP (Nông nghiệp tốt Việt Nam)'),
                  ),
                  DropdownMenuItem(
                    value: 'GlobalGAP',
                    child: Text('GlobalGAP (Chuẩn toàn cầu)'),
                  ),
                  DropdownMenuItem(
                    value: 'Organic USDA',
                    child: Text('Hữu cơ sinh học (Organic)'),
                  ),
                  DropdownMenuItem(
                    value: 'OCOP 4 Sao',
                    child: Text('OCOP 4 Sao Tỉnh'),
                  ),
                ],
                onChanged: (val) => setState(() => _certType = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _certNumberController,
                decoration: const InputDecoration(
                  labelText: 'Số giấy chứng nhận kiểm định',
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Vui lòng nhập số giấy phép' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _inspectorController,
                decoration: const InputDecoration(
                  labelText: 'Cán bộ kiểm định KCS',
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Vui lòng nhập tên cán bộ KCS' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _testResultsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Chỉ số xét nghiệm an toàn',
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Vui lòng nhập kết quả' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yieldController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sản lượng lô hàng (kg)',
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Vui lòng nhập sản lượng' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSaveBatch,
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(
                    _isSaving
                        ? 'Đang upload ảnh và tạo lô hàng...'
                        : 'Tạo lô hàng & Sinh mã QR truy xuất',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
