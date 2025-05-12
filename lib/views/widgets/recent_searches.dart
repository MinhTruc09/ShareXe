import 'package:flutter/material.dart';

class RecentSearches extends StatelessWidget {
  const RecentSearches({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This would typically fetch from local storage or a state management solution
    final List<Map<String, String>> recentSearches = [
      {
        'departure': 'TP. Hồ Chí Minh',
        'destination': 'Đà Lạt',
        'date': '12/08/2023',
      },
      {
        'departure': 'Hà Nội',
        'destination': 'Ninh Bình',
        'date': '05/08/2023',
      },
      {
        'departure': 'Cần Thơ',
        'destination': 'Long An',
        'date': '01/08/2023',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Tìm kiếm gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002D72),
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: recentSearches.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final search = recentSearches[index];
              return ListTile(
                onTap: () {
                  // Implement search with these parameters
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tìm kiếm từ ${search['departure']} đến ${search['destination']}'),
                    ),
                  );
                },
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE6F2FF),
                  child: Icon(Icons.history, color: Color(0xFF002D72)),
                ),
                title: Text(
                  '${search['departure']} - ${search['destination']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Ngày đi: ${search['date']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          ),
        ),
      ],
    );
  }
} 