import 'package:dopamine_assets/auth/account_load_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same session may apply', () {
    expect(
      accountLoadStillCurrent(
        mounted: true,
        loadEpoch: 2,
        currentEpoch: 2,
        loadUid: 'user-a',
        currentUid: 'user-a',
      ),
      isTrue,
    );
  });

  test('sign-out or account switch invalidates the load', () {
    expect(
      accountLoadStillCurrent(
        mounted: true,
        loadEpoch: 2,
        currentEpoch: 3,
        loadUid: 'user-a',
        currentUid: 'user-b',
      ),
      isFalse,
    );
    expect(
      accountLoadStillCurrent(
        mounted: true,
        loadEpoch: 2,
        currentEpoch: 2,
        loadUid: 'user-a',
        currentUid: null,
      ),
      isFalse,
    );
    expect(
      accountLoadStillCurrent(
        mounted: false,
        loadEpoch: 2,
        currentEpoch: 2,
        loadUid: 'user-a',
        currentUid: 'user-a',
      ),
      isFalse,
    );
  });
}
