class KategoriItem {
  final String id;
  final String nama;
  final bool isPemasukan;
  final int iconCode; // Untuk menyimpan icon.codePoint
  final int colorValue; // Untuk menyimpan color.value

  KategoriItem({
    required this.id,
    required this.nama,
    required this.isPemasukan,
    required this.iconCode,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'isPemasukan': isPemasukan,
      'iconCode': iconCode,
      'colorValue': colorValue,
    };
  }

  factory KategoriItem.fromMap(Map<String, dynamic> map) {
    return KategoriItem(
      id: map['id'],
      nama: map['nama'],
      isPemasukan: map['isPemasukan'],
      iconCode: map['iconCode'],
      colorValue: map['colorValue'],
    );
  }
}
