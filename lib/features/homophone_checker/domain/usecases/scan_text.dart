import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../entities/flagged_letter.dart';
import '../repositories/homophone_repository.dart';

/// Scans text and returns every homophone choice point in it.
class ScanText implements UseCase<List<FlaggedLetter>, ScanTextParams> {
  final HomophoneRepository repository;

  const ScanText(this.repository);

  @override
  List<FlaggedLetter> call(ScanTextParams params) =>
      repository.scan(params.text);
}

class ScanTextParams extends Equatable {
  final String text;

  const ScanTextParams(this.text);

  @override
  List<Object?> get props => [text];
}
