import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const MenuItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: item.isAvailable ? Colors.white : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const Spacer(),
              Text(
                item.name,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.description!,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TL ${item.price.toStringAsFixed(2)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.secondaryColor,
                    ),
                  ),
                  if (!item.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "UNAVAILABLE",
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
