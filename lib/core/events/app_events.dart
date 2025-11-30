import '../mediator/app_mediator.dart';
import '../../features/orders/data/models/order_model.dart';

/// ========== ORDER EVENTS ==========

/// Event fired when an order is completed
class OrderCompletedEvent extends AppEvent {
  final String orderId;
  final String? customerId;
  final String? customerName;
  final String cashierName;
  final String cashierId;
  final String? branchId;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String paymentMethod;
  final List<OrderItem> items;
  final DateTime orderDate;
  
  OrderCompletedEvent({
    required this.orderId,
    this.customerId,
    this.customerName,
    required this.cashierName,
    required this.cashierId,
    this.branchId,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.paymentMethod,
    required this.items,
    required this.orderDate,
  });
  
  factory OrderCompletedEvent.fromOrder(String orderId, Order order) {
    return OrderCompletedEvent(
      orderId: orderId,
      customerId: order.customerId,
      customerName: order.customerName,
      cashierName: order.cashierName ?? 'Unknown',
      cashierId: order.cashierId ?? '',
      branchId: order.branchId,
      totalAmount: order.totalAmount,
      taxAmount: order.taxAmount,
      discountAmount: order.discountAmount,
      paymentMethod: order.paymentMethod,
      items: order.items,
      orderDate: order.orderDate,
    );
  }
}

/// Event fired when an order is cancelled
class OrderCancelledEvent extends AppEvent {
  final String orderId;
  final String reason;
  
  OrderCancelledEvent({
    required this.orderId,
    required this.reason,
  });
}

/// ========== PRODUCT EVENTS ==========

/// Event fired when product stock changes
class ProductStockChangedEvent extends AppEvent {
  final String productId;
  final String productName;
  final int oldStock;
  final int newStock;
  final int difference;
  final String reason; // 'sale', 'restock', 'adjustment'
  
  ProductStockChangedEvent({
    required this.productId,
    required this.productName,
    required this.oldStock,
    required this.newStock,
    required this.reason,
  }) : difference = newStock - oldStock;
}

/// Event fired when product reaches critical stock level
class LowStockAlertEvent extends AppEvent {
  final String productId;
  final String productName;
  final int currentStock;
  final int criticalLevel;
  
  LowStockAlertEvent({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.criticalLevel,
  });
}

/// Event fired when a new product is added
class ProductCreatedEvent extends AppEvent {
  final String productId;
  final String productName;
  final double price;
  final int stock;
  
  ProductCreatedEvent({
    required this.productId,
    required this.productName,
    required this.price,
    required this.stock,
  });
}

/// Event fired when product is updated
class ProductUpdatedEvent extends AppEvent {
  final String productId;
  final Map<String, dynamic> changes;
  
  ProductUpdatedEvent({
    required this.productId,
    required this.changes,
  });
}

/// ========== CUSTOMER EVENTS ==========

/// Event fired when customer makes a purchase
class CustomerPurchaseEvent extends AppEvent {
  final String customerId;
  final String customerName;
  final double purchaseAmount;
  final int loyaltyPointsEarned;
  
  CustomerPurchaseEvent({
    required this.customerId,
    required this.customerName,
    required this.purchaseAmount,
    required this.loyaltyPointsEarned,
  });
}

/// Event fired when customer balance changes (credit/veresiye)
class CustomerBalanceChangedEvent extends AppEvent {
  final String customerId;
  final double oldBalance;
  final double newBalance;
  final double change;
  final String reason;
  
  CustomerBalanceChangedEvent({
    required this.customerId,
    required this.oldBalance,
    required this.newBalance,
    required this.reason,
  }) : change = newBalance - oldBalance;
}

/// Event fired when a new customer is created
class CustomerCreatedEvent extends AppEvent {
  final String customerId;
  final String customerName;
  
  CustomerCreatedEvent({
    required this.customerId,
    required this.customerName,
  });
}

/// ========== REGISTER (CASH DRAWER) EVENTS ==========

/// Event fired when register is opened
class RegisterOpenedEvent extends AppEvent {
  final String registerId;
  final String userName;
  final String userId;
  final double openingBalance;
  final DateTime openingTime;
  
  RegisterOpenedEvent({
    required this.registerId,
    required this.userName,
    required this.userId,
    required this.openingBalance,
    required this.openingTime,
  });
}

/// Event fired when register is closed (Z-Report)
class RegisterClosedEvent extends AppEvent {
  final String registerId;
  final String userName;
  final double openingBalance;
  final double closingBalance;
  final double totalCashSales;
  final double totalCardSales;
  final double totalOtherSales;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final DateTime closingTime;
  
  RegisterClosedEvent({
    required this.registerId,
    required this.userName,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalCashSales,
    required this.totalCardSales,
    required this.totalOtherSales,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.closingTime,
  });
}

/// ========== REPORTS EVENTS ==========

/// Event fired to trigger dashboard refresh
class DashboardRefreshEvent extends AppEvent {
  final String source; // 'order', 'product', 'customer'
  
  DashboardRefreshEvent({required this.source});
}

/// Event fired to trigger report generation
class ReportGeneratedEvent extends AppEvent {
  final String reportType; // 'z-report', 'daily', 'monthly'
  final Map<String, dynamic> data;
  
  ReportGeneratedEvent({
    required this.reportType,
    required this.data,
  });
}

/// ========== SYNC EVENTS ==========

/// Event fired when data sync starts
class SyncStartedEvent extends AppEvent {
  final String syncType; // 'manual', 'background', 'scheduled'
  
  SyncStartedEvent({required this.syncType});
}

/// Event fired when data sync completes
class SyncCompletedEvent extends AppEvent {
  final String syncType;
  final int itemsSynced;
  final bool success;
  final String? error;
  
  SyncCompletedEvent({
    required this.syncType,
    required this.itemsSynced,
    required this.success,
    this.error,
  });
}

/// ========== NOTIFICATION EVENTS ==========

/// Event fired to show notification to user
class NotificationEvent extends AppEvent {
  final String title;
  final String message;
  final String type; // 'success', 'error', 'warning', 'info'
  final Duration? duration;
  
  NotificationEvent({
    required this.title,
    required this.message,
    this.type = 'info',
    this.duration,
  });
}

/// ========== ANALYTICS EVENTS ==========

/// Event for tracking user actions
class AnalyticsEvent extends AppEvent {
  final String eventName;
  final Map<String, dynamic> parameters;
  
  AnalyticsEvent({
    required this.eventName,
    required this.parameters,
  });
}
