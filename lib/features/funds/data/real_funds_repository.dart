import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';
import '../domain/funds_repository.dart';

class RealFundsRepository implements FundsRepository {
  final ApiClient _apiClient;

  RealFundsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FundsSummary> getFundsSummary({Segment segment = Segment.EQUITY}) async {
    final data = await _apiClient.get(ApiPaths.fundsSummary);
    final obj = ResponseReader.object(data, 'summary');
    return FundsSummary.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
  }

  @override
  Future<List<LedgerEntry>> getLedger({int page = 1, int limit = 20}) async {
    final data = await _apiClient.get(
      ApiPaths.walletLedger,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = ResponseReader.list(data, 'items');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'ledger');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => LedgerEntry.fromJson(item))
        .toList();
  }

  @override
  Future<WalletTransaction> getTransactionReceipt(String id) async {
    final data = await _apiClient.get(ApiPaths.walletTransactionReceipt(id));
    final obj = ResponseReader.object(data, 'receipt');
    return WalletTransaction.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
  }

  @override
  Future<WalletTransaction> createDeposit({
    required double amount,
    String currency = 'INR',
    String? idempotencyKey,
  }) async {
    // Contract Section 4.2: POST /api/wallet/deposit/create
    final data = await _apiClient.post(
      ApiPaths.walletDepositCreate,
      data: {
        'amount': amount,
        'currency': currency,
      },
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );

    final obj = ResponseReader.object(data, 'deposit');
    return WalletTransaction.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
  }

  @override
  Future<WalletTransaction> verifyDeposit({
    required String depositId,
    String? idempotencyKey,
  }) async {
    // Contract Section 4.3: POST /api/wallet/deposit/verify
    final data = await _apiClient.post(
      ApiPaths.walletDepositVerify,
      data: {'depositId': depositId},
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );

    final obj = ResponseReader.object(data, 'deposit');
    return WalletTransaction.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
  }

  @override
  Future<WalletTransaction> withdraw({
    required double amount,
    required String accountNumber,
    required String ifsc,
    String method = 'BANK_TRANSFER',
    String currency = 'INR',
    String? idempotencyKey,
  }) async {
    // Contract Section 4.4: POST /api/wallet/withdraw
    final data = await _apiClient.post(
      ApiPaths.walletWithdraw,
      data: {
        'amount': amount,
        'currency': currency,
        'paymentDetails': {
          'method': method,
          'accountNumber': accountNumber,
          'ifsc': ifsc,
        },
      },
      options: idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );

    final obj = ResponseReader.object(data, 'withdrawal');
    return WalletTransaction.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
  }
}

final fundsRepositoryProvider = Provider<FundsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RealFundsRepository(apiClient: apiClient);
});

final fundsSummaryProvider = FutureProvider<FundsSummary>((ref) async {
  final repo = ref.watch(fundsRepositoryProvider);
  return repo.getFundsSummary();
});

final walletLedgerProvider = FutureProvider<List<LedgerEntry>>((ref) async {
  final repo = ref.watch(fundsRepositoryProvider);
  return repo.getLedger();
});

final walletTransactionsListProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final repo = ref.watch(fundsRepositoryProvider);
  final ledger = await repo.getLedger();
  return ledger.map((l) => WalletTransaction(
    id: l.id,
    referenceId: l.id,
    type: l.credit > 0 ? WalletTransactionType.DEPOSIT : WalletTransactionType.WITHDRAWAL,
    amount: l.credit > 0 ? l.credit : (l.debit > 0 ? l.debit : 0.0),
    status: WalletTransactionStatus.COMPLETED,
    method: PaymentMethod.UPI,
    createdAt: l.date,
    updatedAt: l.date,
  )).toList();
});
