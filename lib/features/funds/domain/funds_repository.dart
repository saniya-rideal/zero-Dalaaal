import '../../../data/models/models.dart';

abstract class FundsRepository {
  Future<FundsSummary> getFundsSummary({Segment segment = Segment.EQUITY});
  Future<List<LedgerEntry>> getLedger({int page = 1, int limit = 20});
  Future<WalletTransaction> getTransactionReceipt(String id);
  Future<WalletTransaction> createDeposit({
    required double amount,
    String currency = 'INR',
    String? idempotencyKey,
  });
  Future<WalletTransaction> verifyDeposit({
    required String depositId,
    String? idempotencyKey,
  });
  Future<WalletTransaction> withdraw({
    required double amount,
    required String accountNumber,
    required String ifsc,
    String method = 'BANK_TRANSFER',
    String currency = 'INR',
    String? idempotencyKey,
  });
  Future<PaymentOrder> createPaymentOrder({
    required double amount,
    String currency = 'INR',
    String? idempotencyKey,
  });
  Future<PaymentOrder> getPaymentOrder(String id);
  Future<PaymentOrder> cancelPaymentOrder(String id);
  Future<List<WalletTransaction>> getWithdrawals({int page = 1, int limit = 20});
}
