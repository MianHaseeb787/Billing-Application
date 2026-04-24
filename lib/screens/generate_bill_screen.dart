import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class BillGenerationScreen extends StatefulWidget {
  const BillGenerationScreen({super.key});

  @override
  State<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends State<BillGenerationScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> categories = ["Burgers", "Pizza", "Drinks", "Desserts"];

  String selectedCategory = "Burgers";

  /// Cart
  List<Map<String, dynamic>> cart = [];

  /// ADD TO BILL
  void addToCart(Map<String, dynamic> item) {
    final index = cart.indexWhere((e) => e["name"] == item["name"]);

    if (index != -1) {
      setState(() {
        cart[index]["qty"] += 1;
      });
    } else {
      setState(() {
        cart.add({"name": item["name"], "price": item["price"], "qty": 1});
      });
    }
  }

  /// TOTAL
  double get total =>
      cart.fold(0, (sum, item) => sum + (item["price"] * item["qty"]));

  /// GENERATE BILL + LOG
  Future<void> generateBill() async {
    if (cart.isEmpty) return;

    await firestore.collection("salesLogs").add({
      "items": cart,
      "total": total,
      "createdAt": FieldValue.serverTimestamp(),
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Bill Generated",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Total Amount: TL ${total.toStringAsFixed(2)}",
          style: GoogleFonts.montserrat(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                cart.clear();
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,

      /// APPBAR
      appBar: AppBar(
        backgroundColor: AppConstants.secondaryColor,
        toolbarHeight: 120,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              "DinO Dine",
              style: GoogleFonts.montserrat(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            SvgPicture.asset(
              "assets/images/dino_logo.svg",
              height: 55,
              color: Colors.white,
            ),
            const SizedBox(width: 30),
            Text(
              "Generate Bill",
              style: GoogleFonts.montserrat(
                fontSize: 24,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            /// LEFT PANEL
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  /// CATEGORY BUTTONS
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final selected = cat == selectedCategory;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selected
                                  ? AppConstants.secondaryColor
                                  : Colors.white,
                              foregroundColor: selected
                                  ? Colors.white
                                  : AppConstants.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedCategory = cat;
                              });
                            },
                            child: Text(
                              cat,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// MENU ITEMS
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: firestore
                            .collection("menuItems")
                            .where("category", isEqualTo: selectedCategory)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return GridView.builder(
                            itemCount: docs.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 1.4,
                                ),
                            itemBuilder: (context, index) {
                              final item = docs[index];
                              final data = item.data() as Map<String, dynamic>;

                              return GestureDetector(
                                onTap: () => addToCart(data),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        data["name"],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "TL ${data["price"]}",
                                        style: GoogleFonts.montserrat(
                                          color: AppConstants.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            /// RIGHT BILL PANEL
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Text(
                      "Current Bill",
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.secondaryColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];

                          return ListTile(
                            title: Text(item["name"]),
                            subtitle: Text("x${item["qty"]}"),
                            trailing: Text(
                              "TL ${(item["price"] * item["qty"]).toStringAsFixed(2)}",
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "TL ${total.toStringAsFixed(2)}",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.secondaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: generateBill,
                        icon: const Icon(Icons.print, color: Colors.white),
                        label: Text(
                          "Generate / Print Bill",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
