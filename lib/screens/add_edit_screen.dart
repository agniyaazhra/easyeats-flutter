import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/filter_chips_widget.dart';
import 'login_screen.dart';

class AddEditScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddEditScreen({super.key, this.recipe});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _cookTimeController;
  late TextEditingController _imageController;
  String _selectedCategory = kCategories[1];
  String _selectedDifficulty = kDifficulties[1];
  List<TextEditingController> _ingredientControllers = [];
  List<TextEditingController> _stepControllers = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleController = TextEditingController(text: r?.title ?? '');
    _cookTimeController = TextEditingController(text: r?.cookTime ?? '');
    _imageController = TextEditingController(text: r?.image ?? '');
    _selectedCategory =
        (r?.category != null && kCategories.contains(r!.category))
            ? r.category
            : kCategories[1];
    _selectedDifficulty =
        (r?.difficulty != null && kDifficulties.contains(r!.difficulty))
            ? r.difficulty
            : kDifficulties[1];

    // Init ingredient controllers
    if (r != null && r.ingredients.isNotEmpty) {
      _ingredientControllers =
          r.ingredients.map((e) => TextEditingController(text: e)).toList();
    } else {
      _ingredientControllers = [TextEditingController()];
    }

    // Init step controllers
    if (r != null && r.steps.isNotEmpty) {
      _stepControllers =
          r.steps.map((e) => TextEditingController(text: e)).toList();
    } else {
      _stepControllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cookTimeController.dispose();
    _imageController.dispose();
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleUnauthorized(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (ingredients.isEmpty) {
      _showError('Please add at least one ingredient.');
      return;
    }
    if (steps.isEmpty) {
      _showError('Please add at least one step.');
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'difficulty': _selectedDifficulty,
      'cookTime': _cookTimeController.text.trim(),
      'image': _imageController.text.trim(),
      'ingredients': ingredients,
      'steps': steps,
    };

    final provider = context.read<RecipeProvider>();
    bool success;

    if (_isEditing) {
      success = await provider.updateRecipe(widget.recipe!.id, data);
    } else {
      success = await provider.addRecipe(data);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (provider.errorMessage == '__unauthorized__') {
      _handleUnauthorized(context);
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Recipe updated!' : 'Recipe added!',
            style: GoogleFonts.dmSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A3D2B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      _showError(provider.errorMessage ?? 'Something went wrong.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3D2B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Recipe' : 'New Recipe',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isEditing ? 'Update' : 'Save',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFE8A838),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ──────────────────────────────────────────────────
            _SectionHeader('Basic Info'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              label: 'Recipe Title',
              hint: 'e.g. Spaghetti Carbonara',
              icon: Icons.title_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _cookTimeController,
              label: 'Cook Time',
              hint: 'e.g. 30 mins',
              icon: Icons.schedule_rounded,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Cook time is required'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _imageController,
              label: 'Image URL',
              hint: 'https://example.com/image.jpg',
              icon: Icons.image_outlined,
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 24),
            _SectionHeader('Category'),
            const SizedBox(height: 12),
            _buildDropdownRow(
              label: 'Category',
              value: _selectedCategory,
              items: kCategories.where((c) => c != 'All').toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),

            const SizedBox(height: 24),
            _SectionHeader('Difficulty'),
            const SizedBox(height: 12),
            Row(
              children: kDifficulties
                  .where((d) => d != 'All')
                  .map((diff) {
                final isSelected = diff == _selectedDifficulty;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedDifficulty = diff),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A3D2B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A3D2B)
                              : const Color(0xFFDDDAD5),
                        ),
                      ),
                      child: Text(
                        diff,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // ── Ingredients ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader('Ingredients'),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _ingredientControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: Color(0xFF1A3D2B)),
                  label: Text(
                    'Add',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A3D2B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._ingredientControllers.asMap().entries.map((entry) {
              final i = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3D2B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A3D2B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: ctrl,
                        style: GoogleFonts.dmSans(fontSize: 14),
                        decoration: _listInputDecoration(
                            'Ingredient ${i + 1}'),
                      ),
                    ),
                    if (_ingredientControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: Color(0xFFE53935), size: 20),
                        onPressed: () {
                          setState(() {
                            _ingredientControllers[i].dispose();
                            _ingredientControllers.removeAt(i);
                          });
                        },
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ── Steps ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader('Steps'),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _stepControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: Color(0xFF1A3D2B)),
                  label: Text(
                    'Add',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1A3D2B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._stepControllers.asMap().entries.map((entry) {
              final i = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3D2B),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: ctrl,
                        style: GoogleFonts.dmSans(fontSize: 14),
                        maxLines: 3,
                        decoration:
                            _listInputDecoration('Describe step ${i + 1}'),
                      ),
                    ),
                    if (_stepControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: Color(0xFFE53935), size: 20),
                        onPressed: () {
                          setState(() {
                            _stepControllers[i].dispose();
                            _stepControllers.removeAt(i);
                          });
                        },
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 40),

            // ── Submit button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3D2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _isEditing ? 'Update Recipe' : 'Save Recipe',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.dmSans(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.dmSans(color: const Color(0xFFBBBBBB), fontSize: 13),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E2DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E2DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1A3D2B), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: GoogleFonts.dmSans(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E2DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E2DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1A3D2B), width: 1.5),
        ),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  InputDecoration _listInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.dmSans(color: const Color(0xFFBBBBBB), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E2DD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E2DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF1A3D2B), width: 1.5),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}
