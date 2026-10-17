class Complex {
  final double real;
  final double imag;

  Complex(this.real, this.imag);

  // Somma di due numeri complessi
  Complex operator +(Complex other) {
    return Complex(real + other.real, imag + other.imag);
  }

  // Sottrazione di due numeri complessi
  Complex operator -(Complex other) {
    return Complex(real - other.real, imag - other.imag);
  }

  // Moltiplicazione di due numeri complessi
  Complex operator *(Complex other) {
    return Complex(
      real * other.real - imag * other.imag,
      real * other.imag + imag * other.real,
    );
  }

  // Divisione di due numeri complessi
  Complex operator /(Complex other) {
    double denominator = other.real * other.real + other.imag * other.imag;
    return Complex(
      (real * other.real + imag * other.imag) / denominator,
      (imag * other.real - real * other.imag) / denominator,
    );
  }

  @override
  String toString() {
    return "$real ${imag >= 0 ? '+' : '-'} ${imag.abs()}i";
  }
}

void main() {
  Complex c1 = Complex(3, 4);
  Complex c2 = Complex(1, -2);

  print("c1: $c1");
  print("c2: $c2");

  print("Somma: ${c1 + c2}");
  print("Sottrazione: ${c1 - c2}");
  print("Moltiplicazione: ${c1 * c2}");
  print("Divisione: ${c1 / c2}");
}
