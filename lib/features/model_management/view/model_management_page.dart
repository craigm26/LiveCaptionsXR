import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/device_model_config.dart';
import '../../../core/services/model_download_manager.dart';
import '../../../core/services/app_logger.dart';

/// Unified Model Management page with device-aware recommendations
class ModelManagementPage extends StatefulWidget {
  const ModelManagementPage({super.key});

  @override
  State<ModelManagementPage> createState() => _ModelManagementPageState();
}

class _ModelManagementPageState extends State<ModelManagementPage> {
  static final AppLogger _logger = AppLogger.instance;
  
  late ModelDownloadManager _downloadManager;
  DeviceModelConfig? _deviceConfig;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Model status tracking
  Map<String, _ModelStatus> _modelStatuses = {};
  
  @override
  void initState() {
    super.initState();
    _downloadManager = ModelDownloadManager();
    _initializeDeviceConfig();
  }

  Future<void> _initializeDeviceConfig() async {
    try {
      setState(() => _isLoading = true);
      
      if (!kIsWeb && Platform.isAndroid) {
        final registry = DeviceModelRegistry();
        _deviceConfig = await registry.getDeviceConfig();
        _logger.i('📱 Device config loaded: ${_deviceConfig?.deviceId}');
      }
      
      await _refreshModelStatuses();
    } catch (e, st) {
      _logger.e('Failed to initialize device config', error: e, stackTrace: st);
      _errorMessage = 'Failed to detect device capabilities';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshModelStatuses() async {
    final statuses = await _downloadManager.checkAllModelStatus();
    
    _modelStatuses = statuses.map((key, value) => MapEntry(
      key,
      _ModelStatus(
        exists: value['exists'] as bool? ?? false,
        complete: value['complete'] as bool? ?? false,
        downloading: value['downloading'] as bool? ?? false,
        progress: value['progress'] as double? ?? 0.0,
        error: value['error'] as String?,
      ),
    ));
    
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('AI Models'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshModelStatuses,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshModelStatuses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device Info Card
                    _buildDeviceInfoCard(),
                    const SizedBox(height: 24),
                    
                    // Quick Status
                    _buildQuickStatusCard(),
                    const SizedBox(height: 24),
                    
                    // Recommended Models Section
                    _buildSectionHeader(
                      'Recommended for Your Device',
                      Icons.star,
                      Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendedModels(),
                    const SizedBox(height: 32),
                    
                    // Speech Recognition Models
                    _buildSectionHeader(
                      'Speech Recognition (ASR)',
                      Icons.mic,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildAsrModelsSection(),
                    const SizedBox(height: 32),
                    
                    // Multimodal (Vision + Language) Models
                    if (_deviceConfig?.npuAvailable ?? false) ...[
                      _buildSectionHeader(
                        'Multimodal (Vision + Language)',
                        Icons.visibility,
                        Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      _buildMultimodalModelsSection(),
                      const SizedBox(height: 32),
                    ],
                    
                    // Language Models (LLM)
                    _buildSectionHeader(
                      'Chat / LLM',
                      Icons.auto_awesome,
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildLlmModelsSection(),
                    const SizedBox(height: 32),
                    
                    // Utility Models
                    if (_deviceConfig?.npuAvailable ?? false) ...[
                      _buildSectionHeader(
                        'Utility Models',
                        Icons.build,
                        Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      _buildUtilityModelsSection(),
                      const SizedBox(height: 32),
                    ],
                    
                    // Required Models Alert
                    if (!_areRecommendedModelsReady()) ...[
                      _buildRequiredModelsAlert(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Storage Info
                    _buildStorageCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDeviceInfoCard() {
    final bool isNexaCapable = _deviceConfig?.npuAvailable ?? false;
    final String deviceType = _getDeviceTypeName();
    final String asrEngine = _getAsrEngineName();
    final String llmEngine = _getLlmEngineName();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNexaCapable ? Colors.green.shade300 : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isNexaCapable 
                        ? Colors.green.shade50 
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isNexaCapable ? Icons.bolt : Icons.smartphone,
                    color: isNexaCapable ? Colors.green : Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceType,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNexaCapable 
                            ? '✅ NPU Acceleration Available'
                            : 'Standard Processing',
                        style: TextStyle(
                          color: isNexaCapable ? Colors.green : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.mic, 'Speech Recognition', asrEngine),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.psychology, 'AI Enhancement', llmEngine),
            if (_deviceConfig != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.memory, 
                'Device Tier', 
                _deviceConfig!.tier.name.toUpperCase(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatusCard() {
    final totalModels = _modelStatuses.length;
    final downloadedModels = _modelStatuses.values.where((s) => s.complete).length;
    final activeDownloads = _modelStatuses.values.where((s) => s.downloading).length;
    
    final bool allReady = _areRecommendedModelsReady();
    
    return Card(
      elevation: 0,
      color: allReady ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: allReady ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                allReady ? Icons.check : Icons.download,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allReady ? 'Ready to Use!' : 'Setup Needed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: allReady ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    allReady 
                        ? 'All recommended models are downloaded'
                        : 'Download recommended models to get started',
                    style: TextStyle(
                      color: allReady ? Colors.green.shade600 : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$downloadedModels/$totalModels',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Models',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedModels() {
    final bool isNexa = _deviceConfig?.npuAvailable ?? false;
    
    if (isNexa) {
      return _buildNexaRecommendation();
    } else if (!kIsWeb && Platform.isIOS) {
      return _buildIosRecommendation();
    } else {
      return _buildGenericRecommendation();
    }
  }

  Widget _buildNexaRecommendation() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nexa SDK — Full Model Catalog',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your device supports Qualcomm NPU acceleration! '
              'Models are auto-downloaded via the Nexa SDK.',
              style: TextStyle(color: Colors.green.shade800),
            ),
            const SizedBox(height: 16),
            // Primary ASR
            _buildRecommendedModelRow(
              'ASR',
              'Parakeet TDT 0.6B',
              '600 MB',
              Icons.mic,
              Colors.blue,
              isAutoDownload: true,
            ),
            const SizedBox(height: 12),
            // Primary multimodal — KEY model
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'OmniNeural-4B',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⭐ RECOMMENDED',
                                style: TextStyle(color: Colors.teal.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '4 GB • Multimodal — Vision + Language for live captions',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Auto',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildRecommendedModelRow(
              'VLM',
              'SmolVLM 256M (lightweight)',
              '480 MB',
              Icons.visibility,
              Colors.teal,
              isAutoDownload: true,
            ),
            const SizedBox(height: 12),
            _buildRecommendedModelRow(
              'Chat',
              'LFM2 1.2B (chat-only)',
              '750 MB',
              Icons.chat,
              Colors.purple,
              isAutoDownload: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OmniNeural-4B handles both visual context AND text enhancement — ideal for live captions in XR.',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosRecommendation() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apple, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'iOS Optimized Setup',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'iOS uses Apple\'s built-in speech recognition for real-time '
              'transcription. Download Gemma for AI text enhancement.',
              style: TextStyle(color: Colors.blue.shade800),
            ),
            const SizedBox(height: 16),
            _buildRecommendedModelRow(
              'Apple Speech',
              'Built-in iOS',
              'No download',
              Icons.mic,
              Colors.green,
              isBuiltIn: true,
            ),
            const SizedBox(height: 12),
            _buildModelDownloadRow('gemma-3n-E4B-it-int4'),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericRecommendation() {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_for_offline, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Required Downloads',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Download these models to enable speech recognition and AI enhancement.',
              style: TextStyle(color: Colors.amber.shade800),
            ),
            const SizedBox(height: 16),
            _buildModelDownloadRow('whisper-base'),
            const SizedBox(height: 12),
            _buildModelDownloadRow('gemma-3n-E4B-it-int4'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedModelRow(
    String type,
    String name,
    String size,
    IconData icon,
    Color color, {
    bool isAutoDownload = false,
    bool isBuiltIn = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  size,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (isBuiltIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Ready',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else if (isAutoDownload)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Auto',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelDownloadRow(String modelKey) {
    final status = _modelStatuses[modelKey];
    final config = _downloadManager.getModelConfig(modelKey);
    
    if (config == null) return const SizedBox.shrink();
    
    final isDownloaded = status?.complete ?? false;
    final isDownloading = status?.downloading ?? false;
    final progress = status?.progress ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDownloaded ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.type == ModelType.whisper 
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              config.type == ModelType.whisper ? Icons.mic : Icons.auto_awesome,
              color: config.type == ModelType.whisper ? Colors.blue : Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatSize(config.expectedSize),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDownloaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ Ready',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else if (isDownloading)
            SizedBox(
              width: 80,
              child: OutlinedButton(
                onPressed: () => _cancelDownload(modelKey),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _downloadModel(modelKey),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Download'),
            ),
        ],
      ),
    );
  }

  Widget _buildAsrModelsSection() {
    final asrModels = _downloadManager.getModelsByType(ModelType.whisper);
    final isNexa = _deviceConfig?.npuAvailable ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNexa) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your device uses Nexa parakeet-tdt-0.6b-v3-npu for speech recognition (auto-download via SDK)',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Optional Fallback Models:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!kIsWeb && Platform.isIOS) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'iOS uses Apple Speech Recognition (built-in, no download needed)',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...asrModels.map((modelKey) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFullModelCard(modelKey),
        )),
      ],
    );
  }

  Widget _buildLlmModelsSection() {
    final llmModels = _downloadManager.getModelsByType(ModelType.gemma);
    final isNexa = _deviceConfig?.npuAvailable ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNexa) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'NPU chat-only models (for text enhancement without vision):',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildNexaModelInfoCard(
            name: 'LFM2-1.2B NPU',
            description: 'Lightweight chat model for text enhancement. Use if OmniNeural is too large.',
            size: '750 MB',
            icon: Icons.chat,
            color: Colors.purple,
            useCaseTag: 'Chat Only',
          ),
          const SizedBox(height: 12),
          _buildNexaModelInfoCard(
            name: 'LFM2-1.2B-GGUF',
            description: 'GGUF variant of LFM2 for broader compatibility.',
            size: '750 MB',
            icon: Icons.chat,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          Text(
            'CPU/GPU Fallback Models:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...llmModels.map((modelKey) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFullModelCard(modelKey),
        )),
      ],
    );
  }

  Widget _buildMultimodalModelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These models combine vision and language — they can see what\'s on screen and enhance captions with visual context.',
                style: TextStyle(color: Colors.teal.shade800, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildNexaModelInfoCard(
          name: 'OmniNeural-4B',
          description: 'Full multimodal: Chat + Vision (VLM). Best for live captions with visual context.',
          size: '4 GB',
          icon: Icons.visibility,
          color: Colors.teal,
          isRecommended: true,
          useCaseTag: 'Live Captions',
        ),
        const SizedBox(height: 12),
        _buildNexaModelInfoCard(
          name: 'SmolVLM-256M-Instruct',
          description: 'Lightweight multimodal: Chat + Vision. Lower resource usage.',
          size: '480 MB',
          icon: Icons.visibility,
          color: Colors.teal,
          useCaseTag: 'Lightweight Alt',
        ),
      ],
    );
  }

  Widget _buildUtilityModelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'General-purpose Nexa models available for NPU devices. These are not required for live captions.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        _buildNexaModelInfoCard(
          name: 'PaddleOCR NPU',
          description: 'On-device OCR for text recognition.',
          size: '250 MB',
          icon: Icons.document_scanner,
          color: Colors.grey,
        ),
        const SizedBox(height: 12),
        _buildNexaModelInfoCard(
          name: 'EmbeddingGemma 300M',
          description: 'Text embedding model for semantic search.',
          size: '250 MB',
          icon: Icons.data_array,
          color: Colors.grey,
        ),
        const SizedBox(height: 12),
        _buildNexaModelInfoCard(
          name: 'Jina v2 Rerank NPU',
          description: 'Reranker model for search result optimization.',
          size: '1 GB',
          icon: Icons.sort,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildNexaModelInfoCard({
    required String name,
    required String description,
    required String size,
    required IconData icon,
    required Color color,
    bool isRecommended = false,
    String? useCaseTag,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRecommended ? color.withOpacity(0.5) : Colors.grey.shade200,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      if (useCaseTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            useCaseTag,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.storage, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(size, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Auto-download via Nexa SDK',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullModelCard(String modelKey) {
    final status = _modelStatuses[modelKey];
    final config = _downloadManager.getModelConfig(modelKey);
    
    if (config == null) return const SizedBox.shrink();
    
    final isDownloaded = status?.complete ?? false;
    final isDownloading = status?.downloading ?? false;
    final progress = status?.progress ?? 0.0;
    final error = status?.error;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDownloaded ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.storage, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatSize(config.expectedSize),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isDownloaded, isDownloading, error),
              ],
            ),
            
            // Progress bar (if downloading)
            if (isDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Downloading...',
                    style: TextStyle(color: Colors.blue[600], fontSize: 12),
                  ),
                ],
              ),
            ],
            
            // Error message
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Actions
            const SizedBox(height: 16),
            Row(
              children: [
                if (isDownloading) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelDownload(modelKey),
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ] else if (isDownloaded) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteModel(modelKey),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadModel(modelKey),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isDownloaded, bool isDownloading, String? error) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'Error',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    if (isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Downloading',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Ready',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_download, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            'Not Downloaded',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return FutureBuilder<int>(
      future: _getAvailableStorage(),
      builder: (context, snapshot) {
        final availableGb = snapshot.hasData 
            ? (snapshot.data! / (1024 * 1024 * 1024)).toStringAsFixed(1)
            : '...';
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storage, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Storage',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$availableGb GB',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  
  String _getDeviceTypeName() {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isIOS) return 'iOS Device';
    if (_deviceConfig == null) return 'Android Device';
    
    switch (_deviceConfig!.formFactor) {
      case DeviceFormFactor.xrHeadset:
        return 'XR Headset';
      case DeviceFormFactor.arGlasses:
        return 'AR Glasses';
      case DeviceFormFactor.tablet:
        return 'Android Tablet';
      default:
        if (_deviceConfig!.npuAvailable) {
          return 'Snapdragon NPU Device';
        }
        return 'Android Phone';
    }
  }

  String _getAsrEngineName() {
    if (kIsWeb) return 'Not available';
    if (Platform.isIOS) return 'Apple Speech (built-in)';
    if (_deviceConfig?.npuAvailable == true) {
      return 'Nexa ${_deviceConfig!.asrModel.displayName}';
    }
    return 'Whisper (download needed)';
  }

  String _getLlmEngineName() {
    if (kIsWeb) return 'Not available';
    if (_deviceConfig?.npuAvailable == true) {
      return 'Nexa ${_deviceConfig!.llmModel.displayName}';
    }
    return 'Gemma 3n (download needed)';
  }

  bool _areRecommendedModelsReady() {
    if (_deviceConfig?.npuAvailable == true) return true;
    if (!kIsWeb && Platform.isIOS) {
      // iOS needs Gemma
      return _modelStatuses['gemma-3n-E4B-it-int4']?.complete ?? false;
    }
    // Generic Android needs both
    final whisperReady = _modelStatuses['whisper-base']?.complete ?? false;
    final gemmaReady = _modelStatuses['gemma-3n-E4B-it-int4']?.complete ?? false;
    return whisperReady && gemmaReady;
  }

  Widget _buildRequiredModelsAlert() {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Required Models Missing',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The caption pipeline requires Parakeet (ASR) and OmniNeural-4B (LLM) '
              'models to function. Download them to enable spatial captions.',
              style: TextStyle(color: Colors.red.shade800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _pipelineModelChip('Parakeet ASR',
                    _modelStatuses['parakeet-tdt-0.6b-v3-npu']?.complete ?? false),
                const SizedBox(width: 8),
                _pipelineModelChip('OmniNeural-4B',
                    _modelStatuses['OmniNeural-4B']?.complete ?? false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pipelineModelChip(String label, bool ready) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ready ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: ready ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: ready ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Future<int> _getAvailableStorage() async {
    // Placeholder - implement actual storage check
    return 10 * 1024 * 1024 * 1024; // 10 GB placeholder
  }

  Future<void> _downloadModel(String modelKey) async {
    try {
      _logger.i('📥 Starting download: $modelKey');
      await _downloadManager.downloadModel(modelKey);
      await _refreshModelStatuses();
    } catch (e) {
      _logger.e('Download failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelDownload(String modelKey) {
    _downloadManager.resetModel(modelKey);
    _refreshModelStatuses();
  }

  Future<void> _deleteModel(String modelKey) async {
    final config = _downloadManager.getModelConfig(modelKey);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model?'),
        content: Text(
          'Delete ${config?.displayName ?? modelKey}? You\'ll need to download it again to use it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _downloadManager.deleteModel(modelKey);
      await _refreshModelStatuses();
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AI Models'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                'Speech Recognition (ASR)',
                'Converts spoken words to text. Nexa devices use Parakeet, '
                'iOS uses Apple Speech, others use Whisper.',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Multimodal (VLM)',
                'OmniNeural-4B combines vision + language — it can see '
                'visual context and enhance captions accordingly. '
                'Recommended for XR/AR use cases.',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Chat / LLM',
                'Text-only models for caption enhancement, punctuation, '
                'and translation. LFM2-1.2B is lightweight; Gemma 3n is a CPU fallback.',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Nexa Devices',
                'Devices with Qualcomm NPU (Snapdragon 8 Gen 2+) '
                'automatically download optimized models via the Nexa SDK. '
                'Full catalog: Parakeet (ASR), OmniNeural-4B (VLM), '
                'SmolVLM-256M, LFM2-1.2B, PaddleOCR, and more.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }
}

class _ModelStatus {
  final bool exists;
  final bool complete;
  final bool downloading;
  final double progress;
  final String? error;

  _ModelStatus({
    required this.exists,
    required this.complete,
    required this.downloading,
    required this.progress,
    this.error,
  });
}
