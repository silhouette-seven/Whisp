import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final VoidCallback onAddPressed;

  const CustomTabBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment:
                      selectedIndex == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B7FFF), // Blue color from image
                        borderRadius: BorderRadius.circular(21),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabSelected(0),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            'All',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  selectedIndex == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  selectedIndex == 0
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabSelected(1),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            'Favourite',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  selectedIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  selectedIndex == 1
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 24, color: Colors.black12),
          IconButton(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
