import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'menu_screen.dart';
import 'generate_bill_screen.dart';
import 'sales.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
            ],
          ),
        ),

        // actions: [Image.asset("assets/images/Dinazor White.png", height: 80)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            /// LEFT SIDE BUTTONS
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// MENU BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MenuManagementScreen(),
                          ),
                        );
                      },

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Menu Mngt",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Image.asset(
                              "Assets/Images/eating.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// BILL BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BillGenerationScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Gen Bill",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: SvgPicture.asset(
                              "Assets/Images/receipt.svg",
                              fit: BoxFit.contain,
                              color: AppConstants.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Settings ...
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalesScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Sales",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.settings,
                              color: AppConstants.secondaryColor,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 30),

            /// RIGHT SIDE IMAGES
            Expanded(
              flex: 2,
              child: Center(
                child: Expanded(
                  // flex: 3,
                  child: Container(
                    height: 400,
                    child: SvgPicture.asset(
                      "assets/images/t-rex.svg",
                      fit: BoxFit.contain,
                      color: AppConstants.secondaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.secondaryColor, // background color
          borderRadius: BorderRadius.circular(20), // rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          "Dinazor",
          style: GoogleFonts.allison(
            fontWeight: FontWeight.bold,
            fontSize: 46,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
