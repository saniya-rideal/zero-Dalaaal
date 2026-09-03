import 'package:flutter_riverpod/flutter_riverpod.dart';

final balancePrivacyProvider = StateProvider<bool>((ref) => false); // false = Show, true = Mask (••••••)
