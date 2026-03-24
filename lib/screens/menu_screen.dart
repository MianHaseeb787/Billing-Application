import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final List<String> categories = ["Burgers", "Pizza", "Drinks", "Desserts"];

  final List<Map<String, dynamic>> menuItems = [
    {"name": "Cheese Burger", "category": "Burgers", "price": 5.99},
    {"name": "Zinger Burger", "category": "Burgers", "price": 6.99},
    {"name": "Pepperoni Pizza", "category": "Pizza", "price": 8.99},
    {"name": "Margherita Pizza", "category": "Pizza", "price": 7.99},
    {"name": "Coke", "category": "Drinks", "price": 1.99},
    {"name": "Ice Cream", "category": "Desserts", "price": 2.99},
  ];

  String selectedCategory = "Burgers";

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Add New Item",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(hintText: "Enter item name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: "Enter price"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: GoogleFonts.montserrat(color: AppConstants.secondaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryColor,
            ),
            onPressed: () {
              final newItem = _itemController.text.trim();
              final priceText = _priceController.text.trim();
              final price = double.tryParse(priceText);

              if (newItem.isNotEmpty && price != null) {
                setState(() {
                  menuItems.add({
                    "name": newItem,
                    "category": selectedCategory,
                    "price": price,
                  });
                });
                _itemController.clear();
                _priceController.clear();
                Navigator.pop(context);
              }
            },
            child: Text(
              "Add",
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Filter Items
    final filteredItems = menuItems
        .where((item) => item["category"] == selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,

      /// APP BAR
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppConstants.secondaryColor,
        toolbarHeight: 120,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SizedBox(width: 16),
              Text(
                "DinO Dine",
                style: GoogleFonts.montserrat(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 26),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: SvgPicture.asset(
                  "assets/images/dino_logo.svg",
                  height: 58,
                  color: Color.fromARGB(255, 56, 137, 188),
                ),
              ),

              // SizedBox(width: 4),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(1.0, 1.0),
                child: SvgPicture.asset(
                  // width: 48,
                  "assets/images/trex-green.svg",
                  height: 58,
                  // color: Color.fromARGB(255, 56, 137, 188),
                ),
              ),
              SizedBox(width: 20),

              SizedBox(
                width: 1,
                child: Container(height: 40, width: 2, color: Colors.white54),
              ),

              SizedBox(width: 50),
              Text(
                "Menu Management",
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == selectedCategory;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppConstants.secondaryColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 30),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// ITEM NAME
                          Text(
                            item["name"]!,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            "\$${item["price"].toStringAsFixed(2)}",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.secondaryColor,
                            ),
                          ),

                          Icon(Icons.edit, color: AppConstants.secondaryColor),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: GestureDetector(
        onTap: _addNewItem,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppConstants.secondaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                "Add Item",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
