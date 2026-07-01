import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/translation_service.dart';

class CitizenReviewsSheet {
  static void show(BuildContext context, List<Complaint> reviewedComplaints, bool isTelugu) {
    if (reviewedComplaints.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rate_review, color: Theme.of(context).primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isTelugu ? 'పౌరుల అభిప్రాయాలు (${reviewedComplaints.length})' : 'Citizen Reviews (${reviewedComplaints.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: reviewedComplaints.length,
                      itemBuilder: (context, index) {
                        final c = reviewedComplaints[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getCategoryName(c.category, isTelugu),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        int threshold = 0;
                                        if (c.feedbackRating == 'poor') {
                                          threshold = 2;
                                        } else if (c.feedbackRating == 'good') {
                                          threshold = 4;
                                        } else if (c.feedbackRating == 'excellent') {
                                          threshold = 5;
                                        }
                                        return Icon(
                                          starIdx < threshold ? Icons.star : Icons.star_border,
                                          color: Theme.of(context).colorScheme.secondary,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${isTelugu ? 'పౌరుడు' : 'Citizen'}: ${c.citizenName}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      c.feedbackRating == 'excellent'
                                          ? (isTelugu ? 'చాలా బాగుంది' : 'Excellent')
                                          : c.feedbackRating == 'good'
                                              ? (isTelugu ? 'బాగుంది' : 'Good')
                                              : (isTelugu ? 'సరిగాలేదు' : 'Poor'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: c.feedbackRating == 'excellent'
                                            ? Colors.green.shade700
                                            : c.feedbackRating == 'good'
                                                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8)
                                                : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _getCategoryName(String cat, bool isTelugu) {
    switch (cat) {
      case 'Pothole & Road Repair':
        return Trans.t('pothole', isTelugu);
      case 'Waste Management':
        return Trans.t('waste', isTelugu);
      case 'Streetlight Issues':
        return Trans.t('streetlight', isTelugu);
      case 'Water Leakage':
        return Trans.t('water', isTelugu);
      case 'Drainage & Sewerage':
        return Trans.t('drainage', isTelugu);
      case 'Electricity & Power Issues':
        return Trans.t('electricity', isTelugu);
      case 'Public Sanitation':
        return Trans.t('sanitation', isTelugu);
      case 'Agriculture & Irrigation':
        return Trans.t('agriculture', isTelugu);
      case 'Fallen Tree Obstruction':
        return Trans.t('tree', isTelugu);
      case 'Sewage Overflow':
        return Trans.t('sewage', isTelugu);
      default:
        return cat;
    }
  }
}
