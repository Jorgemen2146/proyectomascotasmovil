import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/domain/entities/external_auth.dart';
import 'package:dogplatform/features/authentication/domain/services/external_identity_service.dart';
import 'package:dogplatform/features/authentication/presentation/pages/login_page.dart';
import 'package:dogplatform/features/legal/application/legal_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  for (final entry in <(Key, ExternalAuthProvider)>[
    (const Key('googleLoginButton'), ExternalAuthProvider.google),
    (const Key('appleLoginButton'), ExternalAuthProvider.apple),
    (const Key('facebookLoginButton'), ExternalAuthProvider.facebook),
  ]) {
    testWidgets(
      '${entry.$2.name} inicia SDK sin consultar documentos legales',
      (tester) async {
        var legalDocumentCalls = 0;
        final identity = _RecordingExternalIdentityService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
              externalIdentityServiceProvider.overrideWithValue(identity),
              legalDocumentsProvider.overrideWith((ref) async {
                legalDocumentCalls++;
                return const [];
              }),
            ],
            child: const MaterialApp(home: LoginPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(entry.$1));
        await tester.pumpAndSettle();

        expect(identity.requestedProviders, [entry.$2]);
        expect(legalDocumentCalls, 0);
        expect(find.text('Antes de continuar'), findsNothing);
      },
    );
  }
}

class _RecordingExternalIdentityService implements ExternalIdentityService {
  final List<ExternalAuthProvider> requestedProviders = [];

  @override
  Future<ExternalProviderResult> signIn(ExternalAuthProvider provider) async {
    requestedProviders.add(provider);
    return const ExternalProviderCancelled();
  }

  @override
  Future<void> signOut() async {}
}
