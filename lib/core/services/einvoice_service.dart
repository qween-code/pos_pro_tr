import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xml/xml.dart';

/// E-Fatura Service (GİB Entegrasyonu)
class EInvoiceService {
  final String companyVkn; // Şirket Vergi Kimlik Numarası
  final String companyTitle; // Şirket Ünvanı
  final String integrationUrl; // E-Fatura entegrasyon URL'i
  final String username;
  final String password;

  EInvoiceService({
    required this.companyVkn,
    required this.companyTitle,
    required this.integrationUrl,
    required this.username,
    required this.password,
  });

  /// E-Fatura Oluştur
  Future<EInvoiceResponse> createInvoice(InvoiceData data) async {
    try {
      // UBL-TR XML formatında fatura oluştur
      final xml = _generateInvoiceXML(data);
      
      // GİB'e gönder
      final url = Uri.parse('$integrationUrl/createInvoice');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/xml',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
        body: xml,
      );

      if (response.statusCode == 200) {
        final responseXml = XmlDocument.parse(response.body);
        final uuid = responseXml.findAllElements('UUID').first.text;
        
        return EInvoiceResponse(
          success: true,
          invoiceUuid: uuid,
          invoiceNumber: data.invoiceNumber,
          message: 'E-Fatura başarıyla oluşturuldu',
        );
      } else {
        return EInvoiceResponse(
          success: false,
          message: 'E-Fatura oluşturulamadı: ${response.body}',
        );
      }
    } catch (e) {
      return EInvoiceResponse(
        success: false,
        message: 'Hata: $e',
      );
    }
  }

  /// E-Arşiv Fatura Oluştur (Bireysel müşteriler için)
  Future<EInvoiceResponse> createEArchiveInvoice(InvoiceData data) async {
    try {
      final xml = _generateInvoiceXML(data, isEArchive: true);
      
      final url = Uri.parse('$integrationUrl/createEArchiveInvoice');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/xml',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
        body: xml,
      );

      if (response.statusCode == 200) {
        final responseXml = XmlDocument.parse(response.body);
        final uuid = responseXml.findAllElements('UUID').first.text;
        
        return EInvoiceResponse(
          success: true,
          invoiceUuid: uuid,
          invoiceNumber: data.invoiceNumber,
          message: 'E-Arşiv Fatura başarıyla oluşturuldu',
        );
      } else {
        return EInvoiceResponse(
          success: false,
          message: 'E-Arşiv Fatura oluşturulamadı',
        );
      }
    } catch (e) {
      return EInvoiceResponse(
        success: false,
        message: 'Hata: $e',
      );
    }
  }

  /// Fatura Durumu Sorgula
  Future<InvoiceStatus> checkInvoiceStatus(String uuid) async {
    try {
      final url = Uri.parse('$integrationUrl/getInvoiceStatus?uuid=$uuid');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
      );

      if (response.statusCode == 200) {
        final responseXml = XmlDocument.parse(response.body);
        final status = responseXml.findAllElements('Status').first.text;
        
        switch (status) {
          case 'APPROVED':
            return InvoiceStatus.approved;
          case 'REJECTED':
            return InvoiceStatus.rejected;
          case 'PENDING':
            return InvoiceStatus.pending;
          default:
            return InvoiceStatus.unknown;
        }
      }
      return InvoiceStatus.unknown;
    } catch (e) {
      debugPrint('Fatura durumu sorgulanamadı: $e');
      return InvoiceStatus.unknown;
    }
  }

  /// PDF İndir
  Future<List<int>?> downloadInvoicePDF(String uuid) async {
    try {
      final url = Uri.parse('$integrationUrl/getInvoicePDF?uuid=$uuid');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('PDF indirilemedi: $e');
      return null;
    }
  }

  /// UBL-TR formatında XML oluştur
  String _generateInvoiceXML(InvoiceData data, {bool isEArchive = false}) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    
    builder.element('Invoice', nest: () {
      builder.namespace('urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
      builder.namespace('http://www.w3.org/2001/XMLSchema-instance', 'xsi');
      builder.namespace('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', 'cbc');
      builder.namespace('urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', 'cac');
      
      // UUID
      builder.element('cbc:UUID', nest: data.uuid);
      
      // Fatura No
      builder.element('cbc:ID', nest: data.invoiceNumber);
      
      // Fatura Tarihi
      builder.element('cbc:IssueDate', nest: _formatDate(data.issueDate));
      builder.element('cbc:IssueTime', nest: _formatTime(data.issueDate));
      
      // Fatura Tipi
      builder.element('cbc:InvoiceTypeCode', nest: isEArchive ? 'EARSIVFATURA' : 'SATIS');
      
      // Para Birimi
      builder.element('cbc:DocumentCurrencyCode', nest: 'TRY');
      
      // Satıcı Bilgileri
      builder.element('cac:AccountingSupplierParty', nest: () {
        builder.element('cac:Party', nest: () {
          builder.element('cbc:WebsiteURI', nest: 'www.sirketim.com');
          builder.element('cac:PartyIdentification', nest: () {
            builder.element('cbc:ID', nest: () {
              builder.attribute('schemeID', 'VKN');
              builder.text(companyVkn);
            });
          });
          builder.element('cac:PartyName', nest: () {
            builder.element('cbc:Name', nest: companyTitle);
          });
        });
      });
      
      // Alıcı Bilgileri
      builder.element('cac:AccountingCustomerParty', nest: () {
        builder.element('cac:Party', nest: () {
          if (data.customerVkn != null) {
            builder.element('cac:PartyIdentification', nest: () {
              builder.element('cbc:ID', nest: () {
                builder.attribute('schemeID', 'VKN');
                builder.text(data.customerVkn!);
              });
            });
          }
          builder.element('cac:PartyName', nest: () {
            builder.element('cbc:Name', nest: data.customerName);
          });
          builder.element('cac:PostalAddress', nest: () {
            builder.element('cbc:StreetName', nest: data.customerAddress);
            builder.element('cbc:CityName', nest: data.customerCity);
            builder.element('cac:Country', nest: () {
              builder.element('cbc:Name', nest: 'Türkiye');
            });
          });
        });
      });
      
      // Fatura Kalemleri
      for (var i = 0; i < data.items.length; i++) {
        final item = data.items[i];
        builder.element('cac:InvoiceLine', nest: () {
          builder.element('cbc:ID', nest: (i + 1).toString());
          builder.element('cbc:InvoicedQuantity', nest: () {
            builder.attribute('unitCode', 'C62');
            builder.text(item.quantity.toString());
          });
          builder.element('cbc:LineExtensionAmount', nest: () {
            builder.attribute('currencyID', 'TRY');
            builder.text(item.lineTotal.toStringAsFixed(2));
          });
          
          builder.element('cac:Item', nest: () {
            builder.element('cbc:Name', nest: item.name);
          });
          
          builder.element('cac:Price', nest: () {
            builder.element('cbc:PriceAmount', nest: () {
              builder.attribute('currencyID', 'TRY');
              builder.text(item.unitPrice.toStringAsFixed(2));
            });
          });
          
          // KDV
          builder.element('cac:TaxTotal', nest: () {
            builder.element('cbc:TaxAmount', nest: () {
              builder.attribute('currencyID', 'TRY');
              builder.text(item.taxAmount.toStringAsFixed(2));
            });
            builder.element('cac:TaxSubtotal', nest: () {
              builder.element('cbc:TaxableAmount', nest: () {
                builder.attribute('currencyID', 'TRY');
                builder.text(item.lineTotal.toStringAsFixed(2));
              });
              builder.element('cbc:TaxAmount', nest: () {
                builder.attribute('currencyID', 'TRY');
                builder.text(item.taxAmount.toStringAsFixed(2));
              });
              builder.element('cac:TaxCategory', nest: () {
                builder.element('cbc:Percent', nest: (item.taxRate * 100).toString());
                builder.element('cac:TaxScheme', nest: () {
                  builder.element('cbc:Name', nest: 'KDV');
                  builder.element('cbc:TaxTypeCode', nest: '0015');
                });
              });
            });
          });
        });
      }
      
      // Toplam Tutarlar
      builder.element('cac:TaxTotal', nest: () {
        builder.element('cbc:TaxAmount', nest: () {
          builder.attribute('currencyID', 'TRY');
          builder.text(data.totalTax.toStringAsFixed(2));
        });
      });
      
      builder.element('cac:LegalMonetaryTotal', nest: () {
        builder.element('cbc:LineExtensionAmount', nest: () {
          builder.attribute('currencyID', 'TRY');
          builder.text(data.subtotal.toStringAsFixed(2));
        });
        builder.element('cbc:TaxExclusiveAmount', nest: () {
          builder.attribute('currencyID', 'TRY');
          builder.text(data.subtotal.toStringAsFixed(2));
        });
        builder.element('cbc:TaxInclusiveAmount', nest: () {
          builder.attribute('currencyID', 'TRY');
          builder.text(data.grandTotal.toStringAsFixed(2));
        });
        builder.element('cbc:PayableAmount', nest: () {
          builder.attribute('currencyID', 'TRY');
          builder.text(data.grandTotal.toStringAsFixed(2));
        });
      });
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}

/// Invoice Data Model
class InvoiceData {
  final String uuid;
  final String invoiceNumber;
  final DateTime issueDate;
  final String customerName;
  final String? customerVkn;
  final String customerAddress;
  final String customerCity;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalTax;
  final double grandTotal;

  InvoiceData({
    required this.uuid,
    required this.invoiceNumber,
    required this.issueDate,
    required this.customerName,
    this.customerVkn,
    required this.customerAddress,
    required this.customerCity,
    required this.items,
    required this.subtotal,
    required this.totalTax,
    required this.grandTotal,
  });
}

class InvoiceItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final double taxRate;
  final double taxAmount;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.taxRate,
    required this.taxAmount,
  });
}

class EInvoiceResponse {
  final bool success;
  final String? invoiceUuid;
  final String? invoiceNumber;
  final String message;

  EInvoiceResponse({
    required this.success,
    this.invoiceUuid,
    this.invoiceNumber,
    required this.message,
  });
}

enum InvoiceStatus {
  approved,
  rejected,
  pending,
  unknown,
}
