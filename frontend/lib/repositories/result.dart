/// Result Pattern สำหรับ Data Layer
/// ใช้จัดการผลลัพธ์และความผิดพลาดอย่างปลอดภัย ไม่ปล่อยให้ Exception หลุดไปถึง Presentation/UI
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(data: final d) => d,
    Failure<T>() => null,
  };

  String? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(message: final m) => m,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => success(d),
      Failure<T>(message: final m, exception: final e) => failure(m, e),
    };
  }
}

/// กรณีทำงานสำเร็จ บรรจุข้อมูล [data]
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';
}

/// กรณีเกิดข้อผิดพลาด บรรจุข้อความ [message] และ [exception] (ถ้ามี)
class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);

  @override
  String toString() => 'Failure(message: $message, exception: $exception)';
}
