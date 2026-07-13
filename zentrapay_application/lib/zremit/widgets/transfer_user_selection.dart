import 'package:flutter/material.dart';

class TransferUserSelection extends StatelessWidget {
  const TransferUserSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchBar(),
          const SizedBox(height: 15),
          _userTile("mary_johnson034@Ecobank"),
          _userTile("markpocker2345@Absa"),
          const SizedBox(height: 25),
          const Text(
            "Recent history",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _recent("henry.."),
              _recent("maryjo.."),
              _recent("johny.."),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: const TextField(
      decoration: InputDecoration(
        icon: Icon(Icons.search, size: 20),
        hintText: "mar",
        border: InputBorder.none,
      ),
    ),
  );

  Widget _userTile(String name) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(name, style: const TextStyle(fontSize: 14)),
    ),
  );

  Widget _recent(String name) => Column(
    children: [
      const CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFFF5F5F5),
        child: Icon(Icons.person_outline, color: Colors.black54),
      ),
      const SizedBox(height: 5),
      Text(name, style: const TextStyle(fontSize: 12)),
    ],
  );
}
