class Dompet {
  final String id;
  final String nama;
  double saldo;

  Dompet({
    required this.id,
    required this.nama,
    this.saldo = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'saldo': saldo,
    };
  }

  factory Dompet.fromMap(Map<String, dynamic> map) {
    return Dompet(
      id: map['id'],
      nama: map['nama'],
      saldo: (map['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
