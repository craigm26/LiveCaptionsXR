import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';

class ChatPage extends StatefulWidget {
  final String modelId;
  final String modelName;
  final String modelPath;
  final String modelType;
  final ModelCompatibility? compatibility;

  const ChatPage({
    super.key,
    required this.modelId,
    required this.modelName,
    required this.modelPath,
    required this.modelType,
    this.compatibility,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  LlmWrapper? _llmWrapper;
  VlmWrapper? _vlmWrapper;
  bool _isModelLoading = true;
  bool _isGenerating = false;
  String? _loadError;
  String _currentResponse = '';

  // Determine if this is a VLM model based on model type
  bool get _isVlmModel => widget.modelType == 'multimodal';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _isModelLoading = true;
      _loadError = null;
    });

    try {
      if (_isVlmModel) {
        // Load VLM
        _vlmWrapper = await VlmWrapper.create(
          VlmCreateInput(
            modelName: '', // Empty for GGUF models
            modelPath: widget.modelPath,
            config: ModelConfig(maxTokens: 2048),
            pluginId: widget.compatibility?.requiredPlugin ?? 'cpu_gpu',
          ),
        );
      } else {
        // Load LLM
        _llmWrapper = await LlmWrapper.create(
          LlmCreateInput(
            modelName: '', // Empty for GGUF models
            modelPath: widget.modelPath,
            config: ModelConfig(nCtx: 4096, maxTokens: 2048),
            pluginId: widget.compatibility?.requiredPlugin ?? 'cpu_gpu',
          ),
        );
      }

      setState(() {
        _isModelLoading = false;
      });

      // Add welcome message
      _addSystemMessage(
        'Model loaded successfully! You can now chat with ${widget.modelName}.\n\n'
        '${widget.compatibility?.recommendation ?? ""}',
      );
    } catch (e) {
      setState(() {
        _isModelLoading = false;
        _loadError = e.toString();
      });
      log('Error: $e');
    }
  }

  void _addSystemMessage(String message) {
    if (message.startsWith('Error')) {
      log(message);
    }
    setState(() {
      _messages.add(ChatMessage('system', message));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage('user', message));
    });
    _scrollToBottom();
  }

  void _addAssistantMessage(String message) {
    setState(() {
      _messages.add(ChatMessage('assistant', message));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isGenerating) return;

    _addUserMessage(message);
    _messageController.clear();

    setState(() {
      _isGenerating = true;
      _currentResponse = '';
    });

    try {
      // Apply chat template
      final chatList = _messages.where((m) => m.role != 'system').toList();

      if (_isVlmModel && _vlmWrapper != null) {
        // VLM chat
        final vlmMessages = chatList.map((m) => VlmChatMessage(m.role, [VlmContent('text', m.content)])).toList();

        final template = await _vlmWrapper!.applyChatTemplate(vlmMessages);
        final config = GenerationConfig(maxTokens: 512, samplerConfig: SamplerConfig(temperature: 0.7, topP: 0.95, topK: 40));

        _vlmWrapper!
            .generateStream(template.formattedText, config)
            .listen(
              (result) {
                if (result is LlmStreamToken) {
                  setState(() {
                    _currentResponse += result.text;
                  });
                  _scrollToBottom();
                } else if (result is LlmStreamCompleted) {
                  _addAssistantMessage(_currentResponse);
                  setState(() {
                    _isGenerating = false;
                    _currentResponse = '';
                  });
                } else if (result is LlmStreamError) {
                  _addSystemMessage('Error: ${result.message}');
                  setState(() {
                    _isGenerating = false;
                    _currentResponse = '';
                  });
                }
              },
              onError: (error) {
                _addSystemMessage('Error: $error');
                setState(() {
                  _isGenerating = false;
                  _currentResponse = '';
                });
              },
            );
      } else if (_llmWrapper != null) {
        // LLM chat
        final template = await _llmWrapper!.applyChatTemplate(chatList);
        final config = GenerationConfig(maxTokens: 512, samplerConfig: SamplerConfig(temperature: 0.7, topP: 0.95, topK: 40));

        _llmWrapper!
            .generateStream(template.formattedText, config)
            .listen(
              (result) {
                if (result is LlmStreamToken) {
                  setState(() {
                    _currentResponse += result.text;
                  });
                  _scrollToBottom();
                } else if (result is LlmStreamCompleted) {
                  _addAssistantMessage(_currentResponse);
                  setState(() {
                    _isGenerating = false;
                    _currentResponse = '';
                  });
                } else if (result is LlmStreamError) {
                  _addSystemMessage('Error: ${result.message}');
                  setState(() {
                    _isGenerating = false;
                    _currentResponse = '';
                  });
                }
              },
              onError: (error) {
                _addSystemMessage('Error: $error');
                setState(() {
                  _isGenerating = false;
                  _currentResponse = '';
                });
              },
            );
      }
    } catch (e) {
      _addSystemMessage('Error: $e');
      setState(() {
        _isGenerating = false;
        _currentResponse = '';
      });
    }
  }

  Future<void> _stopGeneration() async {
    try {
      if (_isVlmModel && _vlmWrapper != null) {
        await _vlmWrapper!.stopStream();
      } else if (_llmWrapper != null) {
        await _llmWrapper!.stopStream();
      }

      if (_currentResponse.isNotEmpty) {
        _addAssistantMessage(_currentResponse);
      }

      setState(() {
        _isGenerating = false;
        _currentResponse = '';
      });
    } catch (e) {
      _addSystemMessage('Error stopping generation: $e');
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Clear all messages and reset the conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_isVlmModel && _vlmWrapper != null) {
          await _vlmWrapper!.reset();
        } else if (_llmWrapper != null) {
          await _llmWrapper!.reset();
        }

        setState(() {
          _messages.clear();
        });

        _addSystemMessage('Chat cleared. You can start a new conversation.');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing chat: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Clean up model wrappers
    if (_llmWrapper != null) {
      _llmWrapper!.destroy();
    }
    if (_vlmWrapper != null) {
      _vlmWrapper!.destroy();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.modelName, style: const TextStyle(fontSize: 16)),
            if (widget.compatibility != null)
              Text('${widget.compatibility!.speedText} • ${widget.compatibility!.availablePlugin.toUpperCase()}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [if (!_isModelLoading && _loadError == null) IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearChat, tooltip: 'Clear chat')],
      ),
      body: _isModelLoading
          ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading model...')]),
            )
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Failed to load model', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_currentResponse.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return _buildMessageBubble(_messages[index]);
                      } else {
                        // Show current streaming response
                        return _buildMessageBubble(ChatMessage('assistant', _currentResponse), isStreaming: true);
                      }
                    },
                  ),
                ),

                // Input area
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isGenerating,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isGenerating)
                        IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: _stopGeneration,
                          style: IconButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                          style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {bool isStreaming = false}) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Text(
              message.content,
              style: TextStyle(color: Colors.blue[700], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.smart_toy, size: 20)), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: isUser ? Theme.of(context).primaryColor : Colors.grey[200], borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(message.content, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(isUser ? Colors.white : Colors.black87)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
