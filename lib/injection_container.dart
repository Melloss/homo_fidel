import 'package:get_it/get_it.dart';

import 'features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'features/homophone_checker/domain/repositories/homophone_repository.dart';
import 'features/homophone_checker/domain/usecases/scan_text.dart';
import 'features/homophone_checker/domain/usecases/swap_letter.dart';

final sl = GetIt.instance;

/// Wires the layers together. Registration order is data -> domain ->
/// presentation, so each layer only ever resolves the one beneath it.
Future<void> init() async {
  // --- Presentation -------------------------------------------------------
  // sl.registerFactory(() => CheckerBloc(scanText: sl(), swapLetter: sl()));

  // --- Domain (use cases) -------------------------------------------------
  sl.registerLazySingleton(() => ScanText(sl()));
  sl.registerLazySingleton(() => const SwapLetter());

  // --- Domain (repository contract) -> Data (implementation) --------------
  sl.registerLazySingleton<HomophoneRepository>(
    () => HomophoneRepositoryImpl(localDataSource: sl()),
  );

  // --- Data (sources) -----------------------------------------------------
  sl.registerLazySingleton<FamilyLocalDataSource>(
    () => FamilyLocalDataSourceImpl(),
  );
}
