// ignore_for_file: avoid_implementing_value_types
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';

import '../../../helpers/mock_repositories.dart';

class MockCustomerInfo extends Mock implements CustomerInfo {}

class MockEntitlementInfos extends Mock implements EntitlementInfos {}

class MockEntitlementInfo extends Mock implements EntitlementInfo {}

void main() {
  late MockPurchasesRepository mockPurchasesRepository;
  late MockCrashReportingRepository mockCrashReportingRepository;

  setUp(() {
    mockPurchasesRepository = MockPurchasesRepository();
    mockCrashReportingRepository = MockCrashReportingRepository();
    when(
      () => mockCrashReportingRepository.reportError(any(), any()),
    ).thenAnswer((_) async => null);
  });

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  PremiumSubscriptionCubit buildCubit() {
    return PremiumSubscriptionCubit(
        purchasesRepository: mockPurchasesRepository,
        crashReportingRepository: mockCrashReportingRepository,
      )
      // These tests assert the mocked RevenueCat behavior, which the
      // desktop-premium short-circuit would bypass on a Windows host.
      ..isDesktopPremiumOverride = false;
  }

  void stubSetup() {
    when(() => mockPurchasesRepository.setup()).thenAnswer((_) async {});
  }

  void stubNoSubscriptions() {
    when(
      () => mockPurchasesRepository.hasWeeklySubscription,
    ).thenAnswer((_) async => false);
    when(
      () => mockPurchasesRepository.hasYearlySubscription,
    ).thenAnswer((_) async => false);
    when(
      () => mockPurchasesRepository.hasLifetimePurchase,
    ).thenAnswer((_) async => false);
  }

  void stubWeeklySubscription() {
    when(
      () => mockPurchasesRepository.hasWeeklySubscription,
    ).thenAnswer((_) async => true);
    when(
      () => mockPurchasesRepository.hasYearlySubscription,
    ).thenAnswer((_) async => false);
    when(
      () => mockPurchasesRepository.hasLifetimePurchase,
    ).thenAnswer((_) async => false);
  }

  void stubYearlySubscription() {
    when(
      () => mockPurchasesRepository.hasWeeklySubscription,
    ).thenAnswer((_) async => false);
    when(
      () => mockPurchasesRepository.hasYearlySubscription,
    ).thenAnswer((_) async => true);
    when(
      () => mockPurchasesRepository.hasLifetimePurchase,
    ).thenAnswer((_) async => false);
  }

  void stubLifetimePurchase() {
    when(
      () => mockPurchasesRepository.hasWeeklySubscription,
    ).thenAnswer((_) async => false);
    when(
      () => mockPurchasesRepository.hasYearlySubscription,
    ).thenAnswer((_) async => false);
    when(
      () => mockPurchasesRepository.hasLifetimePurchase,
    ).thenAnswer((_) async => true);
  }

  MockCustomerInfo buildMockCustomerInfo({
    bool hasProEntitlement = false,
    bool isActive = false,
    String productIdentifier = '',
  }) {
    final customerInfo = MockCustomerInfo();
    final entitlementInfos = MockEntitlementInfos();

    if (hasProEntitlement) {
      final entitlementInfo = MockEntitlementInfo();
      when(() => entitlementInfo.isActive).thenReturn(isActive);
      when(
        () => entitlementInfo.productIdentifier,
      ).thenReturn(productIdentifier);
      when(() => entitlementInfos.all).thenReturn({'Pro': entitlementInfo});
    } else {
      when(() => entitlementInfos.all).thenReturn({});
    }

    when(() => customerInfo.entitlements).thenReturn(entitlementInfos);
    return customerInfo;
  }

  group('PremiumSubscriptionCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      expect(cubit.state.status, PremiumSubscriptionStatus.initial);
      expect(cubit.state.hasWeeklySubscription, false);
      expect(cubit.state.hasYearlySubscription, false);
      expect(cubit.state.hasLifetimePurchase, false);
      expect(cubit.state.errorMessage, isNull);
    });

    group('hasPremium', () {
      test('returns false when no subscriptions', () {
        final cubit = buildCubit();
        expect(cubit.hasPremium, false);
      });

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'returns true when has weekly subscription',
        setUp: () {
          stubSetup();
          stubWeeklySubscription();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        verify: (cubit) => expect(cubit.hasPremium, true),
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'returns true when has yearly subscription',
        setUp: () {
          stubSetup();
          stubYearlySubscription();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        verify: (cubit) => expect(cubit.hasPremium, true),
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'returns true when has lifetime purchase',
        setUp: () {
          stubSetup();
          stubLifetimePurchase();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        verify: (cubit) => expect(cubit.hasPremium, true),
      );
    });

    group('init', () {
      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'calls setup and checkStatus on success',
        setUp: () {
          stubSetup();
          stubNoSubscriptions();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.noPremium,
          ),
        ],
        verify: (_) {
          verify(() => mockPurchasesRepository.setup()).called(1);
        },
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits failure when setup throws',
        setUp: () {
          when(
            () => mockPurchasesRepository.setup(),
          ).thenThrow(Exception('Setup failed'));
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          isA<PremiumSubscriptionState>()
              .having(
                (s) => s.status,
                'status',
                PremiumSubscriptionStatus.failure,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Setup failed'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });

    group('checkStatus', () {
      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with weekly subscription',
        setUp: () {
          stubSetup();
          stubWeeklySubscription();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasWeeklySubscription: true,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with yearly subscription',
        setUp: () {
          stubSetup();
          stubYearlySubscription();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasYearlySubscription: true,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with lifetime purchase',
        setUp: () {
          stubSetup();
          stubLifetimePurchase();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasLifetimePurchase: true,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits noPremium when no subscriptions',
        setUp: () {
          stubSetup();
          stubNoSubscriptions();
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.noPremium,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits failure when checkStatus throws',
        setUp: () {
          stubSetup();
          when(
            () => mockPurchasesRepository.hasWeeklySubscription,
          ).thenThrow(Exception('Network error'));
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          isA<PremiumSubscriptionState>()
              .having(
                (s) => s.status,
                'status',
                PremiumSubscriptionStatus.failure,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Network error'),
              ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with multiple subscription types active',
        setUp: () {
          stubSetup();
          when(
            () => mockPurchasesRepository.hasWeeklySubscription,
          ).thenAnswer((_) async => true);
          when(
            () => mockPurchasesRepository.hasYearlySubscription,
          ).thenAnswer((_) async => true);
          when(
            () => mockPurchasesRepository.hasLifetimePurchase,
          ).thenAnswer((_) async => false);
        },
        build: buildCubit,
        act: (cubit) => cubit.init(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasWeeklySubscription: true,
            hasYearlySubscription: true,
          ),
        ],
      );
    });

    group('restore', () {
      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with lifetime when restoring lifetime purchase',
        setUp: () {
          final customerInfo = buildMockCustomerInfo(
            hasProEntitlement: true,
            isActive: true,
            productIdentifier: 'repeatlab_full_extended',
          );
          when(
            () => mockPurchasesRepository.restorePurchases(),
          ).thenAnswer((_) async => customerInfo);
        },
        build: buildCubit,
        act: (cubit) => cubit.restore(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasLifetimePurchase: true,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with weekly when restoring weekly subscription',
        setUp: () {
          final customerInfo = buildMockCustomerInfo(
            hasProEntitlement: true,
            isActive: true,
            productIdentifier: 'repeatlab_full_weekly',
          );
          when(
            () => mockPurchasesRepository.restorePurchases(),
          ).thenAnswer((_) async => customerInfo);
        },
        build: buildCubit,
        act: (cubit) => cubit.restore(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasWeeklySubscription: true,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits premium with yearly when restoring yearly subscription',
        setUp: () {
          final customerInfo = buildMockCustomerInfo(
            hasProEntitlement: true,
            isActive: true,
            productIdentifier: 'repeatlab_full_yearly',
          );
          when(
            () => mockPurchasesRepository.restorePurchases(),
          ).thenAnswer((_) async => customerInfo);
        },
        build: buildCubit,
        act: (cubit) => cubit.restore(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.premium,
            hasYearlySubscription: true,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits noPremium when Pro entitlement is not active',
        setUp: () {
          final customerInfo = buildMockCustomerInfo(
            hasProEntitlement: true,
            productIdentifier: 'repeatlab_full_weekly',
          );
          when(
            () => mockPurchasesRepository.restorePurchases(),
          ).thenAnswer((_) async => customerInfo);
        },
        build: buildCubit,
        act: (cubit) => cubit.restore(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.noPremium,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits noPremium when no Pro entitlement exists',
        setUp: () {
          final customerInfo = buildMockCustomerInfo();
          when(
            () => mockPurchasesRepository.restorePurchases(),
          ).thenAnswer((_) async => customerInfo);
        },
        build: buildCubit,
        act: (cubit) => cubit.restore(),
        expect: () => [
          const PremiumSubscriptionState(
            status: PremiumSubscriptionStatus.noPremium,
          ),
        ],
      );

      blocTest<PremiumSubscriptionCubit, PremiumSubscriptionState>(
        'emits failure when restore throws',
        setUp: () {
          when(
            () => mockPurchasesRepository.restorePurchases(),
          ).thenThrow(Exception('Restore failed'));
        },
        build: buildCubit,
        act: (cubit) => cubit.restore(),
        expect: () => [
          isA<PremiumSubscriptionState>()
              .having(
                (s) => s.status,
                'status',
                PremiumSubscriptionStatus.failure,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Restore failed'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });
  });
}
