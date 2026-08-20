import '../errors/app_failure.dart';

/// Lightweight functional result type used at the boundary between
/// repositories/use cases and the presentation layer, avoiding exceptions
/// as control flow across architectural layers.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(AppFailure failure) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Returns the success value or `null` if this is a [Failure].
  T? get valueOrNull => switch (this) {
    Success<T>(value: final v) => v,
    Failure<T>() => null,
  };

  /// Returns the failure or `null` if this is a [Success].
  AppFailure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(failure: final f) => f,
  };

  /// Pattern-matches on the result, forcing callers to handle both cases.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success<T>(value: final v) => success(v),
      Failure<T>(failure: final f) => failure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value) : super();

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure) : super();

  final AppFailure failure;
}
