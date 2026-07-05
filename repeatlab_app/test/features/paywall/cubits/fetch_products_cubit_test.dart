// ignore_for_file: avoid_implementing_value_types
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/features/paywall/cubits/fetch_products/fetch_products_cubit.dart';

import '../../../helpers/mock_repositories.dart';

class MockOffering extends Mock implements Offering {}

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

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
    registerFallbackValue(MockPackage());
    registerFallbackValue(StackTrace.empty);
  });

  FetchProductsCubit buildCubit() {
    return FetchProductsCubit(
      purchasesRepository: mockPurchasesRepository,
      crashReportingRepository: mockCrashReportingRepository,
    );
  }

  group('FetchProductsCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      expect(cubit.state.status, FetchProductsStatus.loading);
      expect(cubit.state.action, FetchProductsAction.none);
      expect(cubit.state.weeklyPackage, isNull);
      expect(cubit.state.annualPackage, isNull);
      expect(cubit.state.lifetimePackage, isNull);
      expect(cubit.state.isTrialEligible, true);
      expect(cubit.state.errorMessage, isNull);
    });

    group('fetchProducts', () {
      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits success with packages when offerings are available',
        setUp: () {
          final offering = MockOffering();
          final weeklyPkg = MockPackage();
          final annualPkg = MockPackage();
          final lifetimePkg = MockPackage();
          final weeklyProduct = MockStoreProduct();
          final annualProduct = MockStoreProduct();

          when(
            () => weeklyProduct.identifier,
          ).thenReturn('repeatlab_full_weekly');
          when(
            () => annualProduct.identifier,
          ).thenReturn('repeatlab_full_yearly');
          when(() => weeklyPkg.storeProduct).thenReturn(weeklyProduct);
          when(() => annualPkg.storeProduct).thenReturn(annualProduct);
          when(() => offering.weekly).thenReturn(weeklyPkg);
          when(() => offering.annual).thenReturn(annualPkg);
          when(() => offering.lifetime).thenReturn(lifetimePkg);

          when(
            () => mockPurchasesRepository.offers,
          ).thenAnswer((_) async => [offering]);
          when(
            () => mockPurchasesRepository.checkTrialEligibility(any()),
          ).thenAnswer((_) async => true);
        },
        build: buildCubit,
        act: (cubit) => cubit.fetchProducts(),
        expect: () => [
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.loading)
              .having((s) => s.action, 'action', FetchProductsAction.fetch),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.success)
              .having((s) => s.weeklyPackage, 'weeklyPackage', isNotNull)
              .having((s) => s.annualPackage, 'annualPackage', isNotNull)
              .having((s) => s.lifetimePackage, 'lifetimePackage', isNotNull)
              .having((s) => s.isTrialEligible, 'isTrialEligible', true),
        ],
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits success with no trial eligibility',
        setUp: () {
          final offering = MockOffering();
          final weeklyPkg = MockPackage();
          final weeklyProduct = MockStoreProduct();

          when(
            () => weeklyProduct.identifier,
          ).thenReturn('repeatlab_full_weekly');
          when(() => weeklyPkg.storeProduct).thenReturn(weeklyProduct);
          when(() => offering.weekly).thenReturn(weeklyPkg);
          when(() => offering.annual).thenReturn(null);
          when(() => offering.lifetime).thenReturn(null);

          when(
            () => mockPurchasesRepository.offers,
          ).thenAnswer((_) async => [offering]);
          when(
            () => mockPurchasesRepository.checkTrialEligibility(any()),
          ).thenAnswer((_) async => false);
        },
        build: buildCubit,
        act: (cubit) => cubit.fetchProducts(),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.success)
              .having((s) => s.isTrialEligible, 'isTrialEligible', false),
        ],
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits success with empty offerings',
        setUp: () {
          when(
            () => mockPurchasesRepository.offers,
          ).thenAnswer((_) async => []);
        },
        build: buildCubit,
        act: (cubit) => cubit.fetchProducts(),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.success)
              .having((s) => s.weeklyPackage, 'weeklyPackage', isNull)
              .having((s) => s.annualPackage, 'annualPackage', isNull)
              .having((s) => s.lifetimePackage, 'lifetimePackage', isNull),
        ],
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits failure when fetching offers throws',
        setUp: () {
          when(
            () => mockPurchasesRepository.offers,
          ).thenThrow(Exception('Network error'));
        },
        build: buildCubit,
        act: (cubit) => cubit.fetchProducts(),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.failure)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Network error'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });

    group('purchase', () {
      late MockPackage mockPackage;

      setUp(() {
        mockPackage = MockPackage();
      });

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits success when purchase succeeds',
        setUp: () {
          when(
            () => mockPurchasesRepository.purchase(any()),
          ).thenAnswer((_) async => true);
        },
        build: buildCubit,
        act: (cubit) => cubit.purchase(mockPackage),
        expect: () => [
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.loading)
              .having((s) => s.action, 'action', FetchProductsAction.purchase),
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.success,
          ),
        ],
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits failure when purchase returns false',
        setUp: () {
          when(
            () => mockPurchasesRepository.purchase(any()),
          ).thenAnswer((_) async => false);
        },
        build: buildCubit,
        act: (cubit) => cubit.purchase(mockPackage),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.failure)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Something went wrong'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits success when user cancels purchase',
        setUp: () {
          when(() => mockPurchasesRepository.purchase(any())).thenThrow(
            PlatformException(
              code: '1',
              message: 'Purchase was cancelled',
              details: {
                'readable_error_code': 'PURCHASE_CANCELLED',
                'readableErrorCode': 'PURCHASE_CANCELLED',
                'underlyingErrorMessage': '',
              },
            ),
          );
        },
        build: buildCubit,
        act: (cubit) => cubit.purchase(mockPackage),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.success)
              .having((s) => s.action, 'action', FetchProductsAction.none),
        ],
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits success when product already purchased',
        setUp: () {
          when(() => mockPurchasesRepository.purchase(any())).thenThrow(
            PlatformException(
              code: '6',
              message: 'Product already purchased',
              details: {
                'readable_error_code': 'PRODUCT_ALREADY_PURCHASED',
                'readableErrorCode': 'PRODUCT_ALREADY_PURCHASED',
                'underlyingErrorMessage': '',
              },
            ),
          );
        },
        build: buildCubit,
        act: (cubit) => cubit.purchase(mockPackage),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.success)
              .having((s) => s.action, 'action', FetchProductsAction.none),
        ],
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits failure when purchase throws generic exception',
        setUp: () {
          when(
            () => mockPurchasesRepository.purchase(any()),
          ).thenThrow(Exception('Unknown error'));
        },
        build: buildCubit,
        act: (cubit) => cubit.purchase(mockPackage),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.failure)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Unknown error'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );

      blocTest<FetchProductsCubit, FetchProductsState>(
        'emits failure when purchase throws unhandled PlatformException',
        setUp: () {
          when(() => mockPurchasesRepository.purchase(any())).thenThrow(
            PlatformException(
              code: '99',
              message: 'Store error',
              details: {
                'readable_error_code': 'STORE_PROBLEM',
                'readableErrorCode': 'STORE_PROBLEM',
                'underlyingErrorMessage': '',
              },
            ),
          );
        },
        build: buildCubit,
        act: (cubit) => cubit.purchase(mockPackage),
        expect: () => [
          isA<FetchProductsState>().having(
            (s) => s.status,
            'status',
            FetchProductsStatus.loading,
          ),
          isA<FetchProductsState>()
              .having((s) => s.status, 'status', FetchProductsStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
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
