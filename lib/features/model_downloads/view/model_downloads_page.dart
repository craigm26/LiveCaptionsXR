import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/model_downloads_cubit.dart';
import '../models/model_info.dart';
import '../services/model_download_service.dart';
import '../widgets/model_card.dart';
import '../widgets/download_progress_dialog.dart';
import '../widgets/ios_diagnostic_widget.dart';

class ModelDownloadsPage extends StatelessWidget {
  const ModelDownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ModelDownloadsCubit(),
      child: const ModelDownloadsView(),
    );
  }
}

class ModelDownloadsView extends StatelessWidget {
  const ModelDownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ModelDownloadsCubit>().refreshDownloadedModels();
            },
          ),
        ],
      ),
      body: BlocConsumer<ModelDownloadsCubit, ModelDownloadsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<ModelDownloadsCubit>().clearError();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // iOS Diagnostic Widget (only shown on iOS)
              IOSDiagnosticWidget(
                cubit: context.read<ModelDownloadsCubit>(),
              ),
              
              // Header with storage info
              _buildStorageInfo(context, state),
              
              // Models list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.models.length,
                  itemBuilder: (context, index) {
                    final model = state.models[index];
                    final isDownloaded = state.downloadedModels.contains(model.fileName);
                    final isDownloading = state.activeDownloads.contains(model.fileName);
                    final progress = state.downloadProgress[model.fileName];
                    final validationResult = state.validationResults[model.fileName];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ModelCard(
                        model: model,
                        isDownloaded: isDownloaded,
                        isDownloading: isDownloading,
                        progress: progress,
                        validationResult: validationResult,
                        onDownload: () => _handleDownload(context, model),
                        onCancel: () => _handleCancel(context, model.fileName),
                        onDelete: () => _handleDelete(context, model.fileName),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStorageInfo(BuildContext context, ModelDownloadsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<int>(
            future: ModelDownloadService.getAvailableStorage(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final availableGB = (snapshot.data! / (1024 * 1024 * 1024)).toStringAsFixed(1);
                return Text('Available storage: $availableGB GB');
              }
              return const Text('Checking storage...');
            },
          ),
          const SizedBox(height: 4),
          Text('Downloaded models: ${state.downloadedModels.length}/${state.models.length}'),
          if (state.activeDownloads.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Active downloads: ${state.activeDownloads.length}',
              style: const TextStyle(color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  void _handleDownload(BuildContext context, ModelInfo model) {
    // Show confirmation for large files
    if (model.sizeInBytes > 1024 * 1024 * 1024) { // > 1GB
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Large File Download'),
          content: Text(
            'This model is ${model.sizeDisplay}. Downloading may take several minutes and use significant data. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ModelDownloadsCubit>().downloadModel(model);
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    } else {
      context.read<ModelDownloadsCubit>().downloadModel(model);
    }
  }

  void _handleCancel(BuildContext context, String fileName) {
    context.read<ModelDownloadsCubit>().cancelDownload(fileName);
  }

  void _handleDelete(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: const Text('Are you sure you want to delete this model? You will need to download it again to use it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ModelDownloadsCubit>().deleteModel(fileName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 