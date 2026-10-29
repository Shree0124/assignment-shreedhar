import '../../../core/network/api_exception.dart';
import '../domain/visit_rules.dart';

String readableError(Object error) {
  if (error is ApiException) return error.message;
  if (error is VisitRuleException) return error.message;
  return 'Something went wrong. Please try again.';
}
