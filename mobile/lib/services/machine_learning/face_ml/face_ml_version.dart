abstract class VersionedMethod {
  final String method;
  final int version;

  VersionedMethod(this.method, [this.version = 0]);

  const VersionedMethod.empty()
      : method = 'Empty method',
        version = 0;

  Map<String, dynamic> toJson() => {
        'method': method,
        'version': version,
      };
}
