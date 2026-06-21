import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../services/kategori_service.dart';

class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key});

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KategoriItem> pemasukanList = [];
  List<KategoriItem> pengeluaranList = [];


  final List<Color> availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      pemasukanList = KategoriService.getSemuaPemasukan();
      pengeluaranList = KategoriService.getSemuaPengeluaran();
    });
  }

  void _showCategoryDialog({KategoriItem? existingItem, required bool isPemasukan}) {
    final TextEditingController nameController = TextEditingController(text: existingItem?.nama ?? '');
    IconData selectedIcon = existingItem != null 
        ? KategoriService.availableIcons.firstWhere((icon) => icon.codePoint == existingItem.iconCode, orElse: () => Icons.category_rounded)
        : KategoriService.availableIcons[0];
    Color selectedColor = existingItem != null 
        ? Color(existingItem.colorValue) 
        : availableColors[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    existingItem == null ? 'Tambah Kategori' : 'Edit Kategori',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Pilih Ikon', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: KategoriService.availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = KategoriService.availableIcons[index];
                        final isSelected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF006D5B).withValues(alpha: 0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: const Color(0xFF006D5B), width: 2) : null,
                            ),
                            child: Icon(icon, color: isSelected ? const Color(0xFF006D5B) : Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text('Pilih Warna', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: availableColors.length,
                      itemBuilder: (context, index) {
                        final color = availableColors[index];
                        final isSelected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        if (existingItem == null) {
                          // Tambah
                          final newItem = KategoriItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            nama: nameController.text.trim(),
                            isPemasukan: isPemasukan,
                            iconCode: selectedIcon.codePoint,
                            colorValue: selectedColor.value,
                          );
                          await KategoriService.tambahKategori(newItem);
                        } else {
                          // Edit
                          final updatedItem = KategoriItem(
                            id: existingItem.id,
                            nama: nameController.text.trim(),
                            isPemasukan: isPemasukan,
                            iconCode: selectedIcon.codePoint,
                            colorValue: selectedColor.value,
                          );
                          await KategoriService.updateKategori(updatedItem);
                        }

                        _loadData();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D5B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini? Transaksi yang sudah menggunakan kategori ini tidak akan terhapus.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await KategoriService.hapusKategori(id);
              _loadData();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<KategoriItem> list, bool isPemasukan) {
    if (list.isEmpty) {
      return const Center(child: Text('Belum ada kategori.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(item.colorValue).withValues(alpha: 0.1),
              child: Icon(
                KategoriService.availableIcons.firstWhere((icon) => icon.codePoint == item.iconCode, orElse: () => Icons.category_rounded),
                color: Color(item.colorValue),
              ),
            ),
            title: Text(item.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                  onPressed: () => _showCategoryDialog(existingItem: item, isPemasukan: isPemasukan),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => _confirmDelete(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF006D5B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF006D5B),
          tabs: const [
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(pemasukanList, true),
          _buildList(pengeluaranList, false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006D5B),
        onPressed: () {
          _showCategoryDialog(isPemasukan: _tabController.index == 0);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
