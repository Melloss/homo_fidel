import 'package:get_it/get_it.dart';

import 'features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'features/homophone_checker/data/datasources/word_freq_local_data_source.dart';
import 'features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'features/homophone_checker/data/repositories/word_frequency_repository_impl.dart';
import 'features/homophone_checker/domain/repositories/homophone_repository.dart';
import 'features/homophone_checker/domain/repositories/word_frequency_repository.dart';
import 'features/homophone_checker/domain/usecases/scan_text.dart';
import 'features/homophone_checker/domain/usecases/suggest_corrections.dart';
import 'features/homophone_checker/domain/usecases/swap_letter.dart';
import 'features/homophone_checker/presentation/bloc/checker_bloc.dart';

final sl = GetIt.instance;

/// Wires the layers together. Registration order is data -> domain ->
/// presentation, so each layer only ever resolves the one beneath it.
Future<void> init() async {
  // --- Presentation -------------------------------------------------------
  sl.registerFactory(
    () => CheckerBloc(
      scanText: sl(),
      swapLetter: sl(),
      suggestCorrections: sl(),
    ),
  );

  // --- Domain (use cases) -------------------------------------------------
  sl.registerLazySingleton(() => ScanText(sl()));
  sl.registerLazySingleton(() => const SwapLetter());
  sl.registerLazySingleton(
    () => SuggestCorrections(
      families: sl<FamilyLocalDataSource>().families,
      repository: sl(),
    ),
  );

  // --- Domain (repository contracts) -> Data (implementations) ------------
  sl.registerLazySingleton<HomophoneRepository>(
    () => HomophoneRepositoryImpl(localDataSource: sl()),
  );

  // --- Data (sources) -----------------------------------------------------
  sl.registerLazySingleton<FamilyLocalDataSource>(
    () => FamilyLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<WordFreqLocalDataSource>(
    () => WordFreqLocalDataSourceImpl(),
  );

  // Constructed eagerly (so it must come after its data source is
  // registered) because load() lives on the impl, not the contract. If the
  // load fails, isAvailable stays false and the app runs as Mode A only —
  // boot never depends on this succeeding.
  final wordFrequencyRepository =
      WordFrequencyRepositoryImpl(localDataSource: sl());
  sl.registerLazySingleton<WordFrequencyRepository>(
    () => wordFrequencyRepository,
  );
  await wordFrequencyRepository.load();
}
