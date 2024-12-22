import 'dart:math';

num maxIn(List<num> numbers) {
  return numbers.reduce((a, b) => max(a, b));
}
