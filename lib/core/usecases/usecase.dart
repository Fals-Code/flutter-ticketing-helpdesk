/// Base abstract class untuk semua Use Case.
/// [Type] adalah return type, [Params] adalah parameter input.
///
/// Contoh penggunaan:
/// ```dart
/// class GetTicketListUseCase extends UseCase<List<Ticket>, NoParams> { ... }
/// ```
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Digunakan ketika use case tidak membutuhkan parameter.
class NoParams {
  const NoParams();
}
