import 'package:flutter/material.dart';
import 'dart:io';
import '../cubit/model_downloads_cubit.dart';
import '../../../core/services/ios_model_config_service.dart';

/// Widget to display iOS-specific diagnostic information and recommendations
class IOSDiagnosticWidget extends StatelessWidget {
  final ModelDownloadsCubit cubit;

  const IOSDiagnosticWidget({
    super.key,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    final diagnosticInfo = cubit.getIOSRecommendations();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'iOS Model Loading Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecommendationsList(context, diagnosticInfo),
            const SizedBox(height: 12),
            _buildKnownIssuesList(context, diagnosticInfo),
            const SizedBox(height: 12),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(BuildContext context, Map<String, dynamic> diagnosticInfo) {
    final recommendations = diagnosticInfo['recommendations'] as Map<String, dynamic>?;
    if (recommendations == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Settings:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                entry.value == true ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: entry.value == true 
                    ? Colors.green 
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatRecommendationKey(entry.key)}: ${entry.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildKnownIssuesList(BuildContext context, Map<String, dynamic> diagnosticInfo) {
    final knownIssues = diagnosticInfo['knownIssues'] as List<dynamic>?;
    if (knownIssues == null || knownIssues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Known iOS Issues:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        ...knownIssues.map((issue) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDetailedDiagnostics(context),
            icon: const Icon(Icons.bug_report),
            label: const Text('View Details'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _validateAllModels(context),
            icon: const Icon(Icons.verified),
            label: const Text('Validate Models'),
          ),
        ),
      ],
    );
  }

  String _formatRecommendationKey(String key) {
    switch (key) {
      case 'useMetalDelegate':
        return 'Use Metal Delegate';
      case 'disableXNNPACK':
        return 'Disable XNNPACK';
      case 'enableMemoryMapping':
        return 'Enable Memory Mapping';
      case 'maxModelSizeGB':
        return 'Max Model Size (GB)';
      case 'enableVerboseLogging':
        return 'Enable Verbose Logging';
      default:
        return key;
    }
  }

  void _showDetailedDiagnostics(BuildContext context) {
    final diagnosticInfo = cubit.getIOSRecommendations();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('iOS Diagnostic Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Platform: ${diagnosticInfo['platform']}'),
              Text('Version: ${diagnosticInfo['version']}'),
              const SizedBox(height: 16),
              const Text(
                'Detailed Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...diagnosticInfo['recommendations'].entries.map((entry) => 
                Text('• ${_formatRecommendationKey(entry.key)}: ${entry.value}')).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _validateAllModels(BuildContext context) async {
    final state = cubit.state;
    final modelsToValidate = state.models.where(
      (model) => state.downloadedModels.contains(model.fileName)
    ).toList();

    if (modelsToValidate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No downloaded models to validate')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Validating models...'),
          ],
        ),
      ),
    );

    try {
      for (final model in modelsToValidate) {
        await cubit.validateModel(model.fileName);
      }
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model validation completed')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validation error: $e')),
      );
    }
  }
} 