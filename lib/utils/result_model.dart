import 'package:equatable/equatable.dart';

class ResultModel extends Equatable {
  final String output;
  final String expression;
  final DateTime dateTime;

  /// Angle mode the expression was evaluated in (matters for sin/cos/tan).
  final bool degrees;
  const ResultModel({
    required this.output,
    required this.expression,
    required this.dateTime,
    this.degrees = true,
  });

  factory ResultModel.empty() {
    return ResultModel(
      output: '',
      expression: '',
      dateTime: DateTime.now(),
    );
  }

  factory ResultModel.formatError() {
    return ResultModel(
      output: 'Format Error',
      expression: '',
      dateTime: DateTime.now(),
    );
  }
  factory ResultModel.error(String error) {
    return ResultModel(
      output: error,
      expression: '',
      dateTime: DateTime.now(),
    );
  }
  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      output: json['output'],
      expression: json['expression'],
      dateTime: DateTime.parse(json['dateTime']),
      degrees: json['degrees'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'output': output,
      'expression': expression,
      'dateTime': dateTime.toIso8601String(),
      'degrees': degrees,
    };
  }

  @override
  List<Object?> get props => [output, expression];
}
