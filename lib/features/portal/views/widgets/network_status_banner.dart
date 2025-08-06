import 'package:flutter/material.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne. Certaines fonctionnalités sont limitées.',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
