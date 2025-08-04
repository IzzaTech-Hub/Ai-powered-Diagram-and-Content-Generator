import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentViewer extends StatefulWidget {
  final String content;
  final String documentType;

  const DocumentViewer({
    super.key,
    required this.content,
    required this.documentType,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLongContent = widget.content.length > 1000;
    final displayContent =
        _isExpanded || !isLongContent
            ? widget.content
            : '${widget.content.substring(0, 1000)}...';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with document type and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDocumentTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getDocumentTypeColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDocumentTypeIcon(),
                        size: 14,
                        color: _getDocumentTypeColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.documentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getDocumentTypeColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.content.split('\n').length} lines • ${widget.content.split(' ').length} words',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Copy All'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 16),
                              SizedBox(width: 8),
                              Text('Export'),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (value) {
                    switch (value) {
                      case 'copy':
                        Clipboard.setData(ClipboardData(text: widget.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document copied to clipboard'),
                          ),
                        );
                        break;
                      case 'export':
                        // Export functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export feature coming soon'),
                          ),
                        );
                        break;
                    }
                  },
                ),
              ],
            ),
          ),

          // Content area
          Container(
            constraints: BoxConstraints(maxHeight: _isExpanded ? 600 : 300),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  displayContent,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),

          // Expand/Collapse button for long content
          if (isLongContent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                ),
                label: Text(
                  _isExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDocumentTypeColor() {
    switch (widget.documentType.toLowerCase()) {
      case 'business':
        return Colors.blue;
      case 'project':
        return Colors.green;
      case 'technical':
        return Colors.purple;
      case 'academic':
        return Colors.indigo;
      case 'marketing':
        return Colors.orange;
      case 'legal':
        return Colors.brown;
      case 'report':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentTypeIcon() {
    switch (widget.documentType.toLowerCase()) {
      case 'business':
        return Icons.business_center;
      case 'project':
        return Icons.assignment;
      case 'technical':
        return Icons.code;
      case 'academic':
        return Icons.school;
      case 'marketing':
        return Icons.campaign;
      case 'legal':
        return Icons.gavel;
      case 'report':
        return Icons.analytics;
      default:
        return Icons.description;
    }
  }
}
