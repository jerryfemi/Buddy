import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SyncOperationRunner {
  static const int _maxAttempts = 3;

  static Future<T> runWithRetry<T>({
    required String collection,
    required String docId,
    required String operation,
    required Future<T> Function() action,
  }) async {
    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error, stackTrace) {
        lastError = error;
        lastStack = stackTrace;

        _logError(
          collection: collection,
          docId: docId,
          operation: operation,
          error: error,
          attempt: attempt,
          maxAttempts: _maxAttempts,
        );

        if (attempt < _maxAttempts) {
          final backoffMs = 250 * (1 << (attempt - 1));
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ?? StateError('Sync operation failed without an error.'),
      lastStack ?? StackTrace.current,
    );
  }

  static void _logError({
    required String collection,
    required String docId,
    required String operation,
    required Object error,
    required int attempt,
    required int maxAttempts,
  }) {
    final code = error is FirebaseException ? error.code : 'unknown';
    debugPrint(
      '[sync-error] collection=$collection docId=$docId op=$operation '
      'code=$code attempt=$attempt/$maxAttempts error=$error',
    );
  }
}
