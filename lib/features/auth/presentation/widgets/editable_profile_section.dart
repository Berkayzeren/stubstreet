// lib/features/auth/presentation/widgets/editable_profile_section.dart

import 'package:flutter/material.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';
import '../../../../shared_widgets/responsive_form_field.dart';

class EditableProfileSection extends StatefulWidget {
  final String title;
  final String content;
  final bool isEditable;
  final Function(String) onEdit;
  final int? maxLines;
  final String? hintText;
  final IconData? icon;
  final bool isInterests;

  const EditableProfileSection({
    super.key,
    required this.title,
    required this.content,
    required this.isEditable,
    required this.onEdit,
    this.maxLines,
    this.hintText,
    this.icon,
    this.isInterests = false,
  });

  @override
  State<EditableProfileSection> createState() => _EditableProfileSectionState();
}

class _EditableProfileSectionState extends State<EditableProfileSection>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _currentContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _currentContent = widget.content;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditableProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _currentContent = widget.content;
      if (!_isEditing) {
        _controller.text = widget.content;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;

    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsivePadding.responsive(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: isDesktop ? 24 : 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 18 : 16,
                    ),
                  ),
                ),
                if (widget.isEditable && !_isLoading) ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isEditing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: const ValueKey('cancel'),
                                icon: const Icon(Icons.close),
                                onPressed: _cancelEdit,
                                tooltip: 'Cancel',
                                iconSize: isDesktop ? 24 : 20,
                              ),
                              IconButton(
                                key: const ValueKey('save'),
                                icon: const Icon(Icons.check),
                                onPressed: _saveEdit,
                                tooltip: 'Save',
                                iconSize: isDesktop ? 24 : 20,
                                color: colorScheme.primary,
                              ),
                            ],
                          )
                        : IconButton(
                            key: const ValueKey('edit'),
                            icon: const Icon(Icons.edit),
                            onPressed: _startEdit,
                            tooltip: 'Edit ${widget.title}',
                            iconSize: isDesktop ? 24 : 20,
                          ),
                  ),
                ],
                if (_isLoading)
                  SizedBox(
                    width: isDesktop ? 24 : 20,
                    height: isDesktop ? 24 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content area
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isEditing
                  ? _buildEditingContent(theme, colorScheme)
                  : _buildDisplayContent(theme, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayContent(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      key: const ValueKey('display'),
      width: double.infinity,
      child: widget.isInterests
          ? _buildInterestsDisplay(theme, colorScheme)
          : _buildTextDisplay(theme, colorScheme),
    );
  }

  Widget _buildTextDisplay(ThemeData theme, ColorScheme colorScheme) {
    final isEmpty = _currentContent.isEmpty || 
                   _currentContent.startsWith('No ') ||
                   _currentContent.startsWith('Not ');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        _currentContent,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildInterestsDisplay(ThemeData theme, ColorScheme colorScheme) {
    if (_currentContent.isEmpty || _currentContent.startsWith('No ')) {
      return _buildTextDisplay(theme, colorScheme);
    }

    final interests = _currentContent.split(',').map((e) => e.trim()).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        return Chip(
          label: Text(interest),
          backgroundColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: colorScheme.onPrimaryContainer,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditingContent(ThemeData theme, ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        key: const ValueKey('editing'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveTextFormField(
              controller: _controller,
              focusNode: _focusNode,
              labelText: 'Edit ${widget.title}',
              hintText: widget.hintText ?? 'Enter your ${widget.title.toLowerCase()}',
              maxLines: widget.maxLines ?? (widget.title.toLowerCase() == 'bio' ? 4 : 1),
              minLines: widget.title.toLowerCase() == 'bio' ? 2 : 1,
              textInputAction: TextInputAction.newline,
              onFieldSubmitted: (value) {
                if (widget.maxLines == null || widget.maxLines == 1) {
                  _saveEdit();
                }
              },
            ),
            
            const SizedBox(height: 12),
            
            // Helper text for interests
            if (widget.isInterests)
              Text(
                'Separate interests with commas (e.g., Music, Sports, Travel)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Action buttons (mobile only)
            if (context.isMobile)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveEdit,
                    child: const Text('Save'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
      _controller.text = _currentContent;
    });
    _animationController.forward();
    
    // Focus after animation completes
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _controller.text = _currentContent;
    });
    _animationController.reverse();
  }

  Future<void> _saveEdit() async {
    final newContent = _controller.text.trim();
    
    if (newContent == _currentContent) {
      _cancelEdit();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Optimistic update
      setState(() {
        _currentContent = newContent;
        _isEditing = false;
      });
      
      _animationController.reverse();
      
      // Call the update function
      await widget.onEdit(newContent);
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _currentContent = widget.content;
        _controller.text = widget.content;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${widget.title.toLowerCase()}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Specialized widgets for different content types
class EditableBioSection extends StatelessWidget {
  final String content;
  final bool isEditable;
  final Function(String) onEdit;

  const EditableBioSection({
    super.key,
    required this.content,
    required this.isEditable,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return EditableProfileSection(
      title: 'Bio',
      content: content,
      isEditable: isEditable,
      onEdit: onEdit,
      maxLines: 4,
      hintText: 'Tell us about yourself...',
      icon: Icons.person,
    );
  }
}

class EditableInterestsSection extends StatelessWidget {
  final List<String> interests;
  final bool isEditable;
  final Function(String) onEdit;

  const EditableInterestsSection({
    super.key,
    required this.interests,
    required this.isEditable,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return EditableProfileSection(
      title: 'Interests',
      content: interests.isNotEmpty ? interests.join(', ') : 'No interests added',
      isEditable: isEditable,
      onEdit: onEdit,
      maxLines: 2,
      hintText: 'Music, Sports, Travel, etc.',
      icon: Icons.interests,
      isInterests: true,
    );
  }
}

class EditableLocationSection extends StatelessWidget {
  final String? location;
  final bool isEditable;
  final Function(String) onEdit;

  const EditableLocationSection({
    super.key,
    required this.location,
    required this.isEditable,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return EditableProfileSection(
      title: 'Location',
      content: location ?? 'No location specified',
      isEditable: isEditable,
      onEdit: onEdit,
      maxLines: 1,
      hintText: 'City, Country',
      icon: Icons.location_on,
    );
  }
}
