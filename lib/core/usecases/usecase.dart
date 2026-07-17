/// Base contract every use case implements: a single business action,
/// invoked as a callable.
///
/// Synchronous on purpose — the Mode A engine is pure arithmetic with no IO,
/// and an async signature here would force `await` ceremony through the bloc
/// for nothing. Revisit only if Mode B (asset-loaded word frequencies) lands.
abstract interface class UseCase<Output, Params> {
  Output call(Params params);
}
