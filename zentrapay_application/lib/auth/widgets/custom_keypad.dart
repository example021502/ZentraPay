import 'package:flutter/material.dart';

class CustomKeypad extends StatelessWidget {
  final Function(String) onDigitPress;
  final VoidCallback onDelete;

  const CustomKeypad({
    super.key,
    required this.onDigitPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) return const SizedBox.shrink();
        if (index == 10) return _buildKey("0");
        if (index == 11) return _buildDeleteKey();
        return _buildKey("${index + 1}");
      },
    );
  }

  Widget _buildKey(String value) => GestureDetector(
    onTap: () => onDigitPress(value),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  Widget _buildDeleteKey() => GestureDetector(
    onTap: onDelete,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(child: Icon(Icons.backspace_outlined)),
    ),
  );
}
