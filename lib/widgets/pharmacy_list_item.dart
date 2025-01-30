import 'package:flutter/material.dart';
import '../models/pharmacy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class PharmacyListItem extends StatelessWidget {
  final Pharmacy pharmacy;
  final VoidCallback onRequestMedication;
  final Position? currentPosition;

  const PharmacyListItem({
    Key? key,
    required this.pharmacy,
    required this.onRequestMedication,
    this.currentPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          pharmacy.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pharmacy.address),
            const SizedBox(height: 4),
            if (pharmacy.distance != null)
              Row(
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pharmacy.distance! < 1
                        ? '${(pharmacy.distance! * 1000).toStringAsFixed(0)} m'
                        : '${pharmacy.distance!.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.medical_services),
              onPressed: onRequestMedication,
              tooltip: 'Request Medication',
            ),
            IconButton(
              icon: const Icon(Icons.directions),
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              tooltip: 'Get Directions',
            ),
          ],
        ),
      ),
    );
  }
}
