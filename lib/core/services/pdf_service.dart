import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/orders/data/models/order_model.dart' as models;
import '../../features/orders/data/repositories/hybrid_order_repository.dart';
import '../database/database_instance.dart';

class PdfService {
  late final HybridOrderRepository _orderRepository;

  PdfService() {
    final dbInstance = Get.find<DatabaseInstance>();
    _orderRepository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: FirebaseFirestore.instance,
    );
  }

  Future<void> printOrderReceipt(models.Order order) async {
    final fullOrder = await _orderRepository.getOrderById(order.id!);
    if (fullOrder == null) return;
    
    final items = fullOrder.items;
    final doc = pw.Document();
    
    // Türkçe karakter desteği için font yükleme (Varsayılan font bazı karakterleri desteklemeyebilir)
    // Şimdilik varsayılan fontu kullanacağız, gerekirse asset font eklenebilir.
    final font = await PdfGoogleFonts.nunitoExtraLight();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 80mm Termal Yazıcı Kağıdı
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('POS PRO TR', style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text('Market & Magaza', style: pw.TextStyle(font: font, fontSize: 12)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tarih:', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text(DateFormat('dd.MM.yyyy HH:mm').format(order.orderDate), style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Fis No:', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('#${order.id?.substring(0, 8) ?? "---"}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              if (order.customerName != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Musteri:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text(order.customerName!, style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              pw.Divider(),
              pw.SizedBox(height: 5),
              
              // Ürün Listesi
              ...items.map((item) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('${item.quantity} x ${item.productName}', style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                    pw.Text('TL${item.totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              )).toList(),
              
              pw.SizedBox(height: 5),
              pw.Divider(),
              
              // Toplamlar
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ara Toplam:', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('TL${(order.totalAmount - order.taxAmount).toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('KDV:', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('TL${order.taxAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              if (order.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Iskonto:', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('-TL${order.discountAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GENEL TOPLAM:', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('TL${order.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Tesekkur Ederiz', style: pw.TextStyle(font: font, fontSize: 12, fontStyle: pw.FontStyle.italic)),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Fis_${order.id}',
    );
  }
}
