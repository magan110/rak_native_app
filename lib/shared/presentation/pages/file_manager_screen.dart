import 'package:flutter/material.dart';

/// File Manager Screen
class FileManagerScreen extends StatelessWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleFiles = [
      FileItem(
        name: 'Product_Spec_2024.pdf',
        size: '2.4 MB',
        type: 'PDF',
        icon: Icons.picture_as_pdf,
        color: Colors.red,
      ),
      FileItem(
        name: 'Sample_Report.docx',
        size: '1.2 MB',
        type: 'DOC',
        icon: Icons.description,
        color: Colors.blue,
      ),
      FileItem(
        name: 'Paint_Catalog.xlsx',
        size: '850 KB',
        type: 'XLS',
        icon: Icons.table_chart,
        color: Colors.green,
      ),
      FileItem(
        name: 'Project_Photos',
        size: '15.7 MB',
        type: 'Folder',
        icon: Icons.folder,
        color: Colors.amber,
      ),
      FileItem(
        name: 'Invoice_2024.pdf',
        size: '345 KB',
        type: 'PDF',
        icon: Icons.picture_as_pdf,
        color: Colors.red,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('File Manager'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStorageCard(),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Recent Files',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            ...sampleFiles.map((file) => _buildFileItem(file)),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  size: 32,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Storage',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '4.2 GB of 10 GB used',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.42,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(FileItem file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: file.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(file.icon, color: file.color, size: 28),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        subtitle: Text(
          '${file.size} • ${file.type}',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }
}

class FileItem {
  final String name;
  final String size;
  final String type;
  final IconData icon;
  final Color color;

  FileItem({
    required this.name,
    required this.size,
    required this.type,
    required this.icon,
    required this.color,
  });
}
