import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class KartuSaldo extends StatelessWidget {
  // Siapkan "keranjang" untuk menerima data dari Home Screen
  final double saldo;
  final double totalPemasukan;
  final double totalPengeluaran;
  final String waktuUpdate;

  const KartuSaldo({
    super.key,
    required this.saldo,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.waktuUpdate,
  });

  String _formatSingkat(double angka) {
    if (angka >= 1000000000) {
      double val = angka / 1000000000;
      return 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',')} M';
    } else if (angka >= 1000000) {
      double val = angka / 1000000;
      return 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',')} Jt';
    } else {
      return formatRupiah(angka); // memanggil fungsi bawaan yang sudah ada
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20), // Padding dalam biar lega
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF18A58D), Color(0xFF096C5B)], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF045C4A).withOpacity(0.3), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5))],
              ),
              //STACK DIMULAI DI SINI 
              child: Stack(
                clipBehavior: Clip.none, 
                children: [
                  
                  // GAMBAR DOMPET (DI BACKGROUND)
                  Positioned(
                    top: -70, 
                    right: -25, 
                    child: Image.asset(
                      'assets/images/dompet3d.png',
                      height: 265, 
                      fit: BoxFit.contain,
                    ),
                  ),

                  //KONTEN UTAMA (DI DEPAN)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Area Saldo Utama
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Saldo Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.55, // Batasi lebar teks biar ga nabrak dompet
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatRupiah(saldo), 
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time, color: Colors.white70, size: 10),
                                const SizedBox(width: 4),
                                Text('Update terakhir: $waktuUpdate', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25), 
                      const Divider(color: Colors.white24), // GARIS PEMBATAS HORIZONTA
                      const SizedBox(height: 12), 

                      // KODE PEMASUKAN & PENGELUARAN 
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 14, child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      Text(
                                        _formatSingkat(totalPemasukan), 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 25, width: 1, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 14, child: const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      Text(
                                        _formatSingkat(totalPengeluaran), 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                ],
              ),
            );
  }
}