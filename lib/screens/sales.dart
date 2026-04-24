import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  double getGrandTotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["total"] ?? 0).toDouble();
    }
    return total;
  }

  int getTotalOrders(List<QueryDocumentSnapshot> docs) {
    return docs.length;
  }

  int getTotalItems(List<QueryDocumentSnapshot> docs) {
    int count = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final items = data["items"] as List<dynamic>? ?? [];

      for (var item in items) {
        count += (item["qty"] ?? 0) as int;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,

      /// APPBAR
      appBar: AppBar(
        backgroundColor: AppConstants.secondaryColor,
        toolbarHeight: 110,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Sales Dashboard",
          style: GoogleFonts.montserrat(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection("salesLogs")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            final totalSales = getGrandTotal(docs);
            final totalOrders = getTotalOrders(docs);
            final totalItems = getTotalItems(docs);

            return Column(
              children: [
                /// TOP STATS
                Row(
                  children: [
                    _statCard(
                      title: "Total Sales",
                      value: "TL ${totalSales.toStringAsFixed(2)}",
                      flex: 2,
                    ),
                    const SizedBox(width: 20),
                    _statCard(title: "Orders", value: "$totalOrders"),
                    const SizedBox(width: 20),
                    _statCard(title: "Items Sold", value: "$totalItems"),
                  ],
                ),

                const SizedBox(height: 24),

                /// SALES LIST
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: docs.isEmpty
                        ? Center(
                            child: Text(
                              "No Sales Yet",
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final sale = docs[index];
                              final data = sale.data() as Map<String, dynamic>;

                              final List items = data["items"] ?? [];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Order #${docs.length - index}",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "TL ${(data["total"] ?? 0).toStringAsFixed(2)}",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    ...items.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          "${item["name"]}  x${item["qty"]}",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    if (data["createdAt"] != null)
                                      Text(
                                        data["createdAt"].toDate().toString(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
