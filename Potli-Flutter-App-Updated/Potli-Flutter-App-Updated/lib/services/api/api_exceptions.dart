class CustomException implements Exception {
  CustomException([this._message, this._prefix]);

  final dynamic _message;
  final dynamic _prefix;

  @override
  String toString() => "$_prefix$_message";
}

class FetchDataException extends CustomException {
  FetchDataException([message])
    : super(message, "Error During Communication: ");
}

class BadRequestException extends CustomException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends CustomException {
  InvalidInputException([message]) : super(message, "Invalid Input: ");
}
