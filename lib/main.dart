import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

void main() {
  Stripe.publishableKey = 'pk_test_51UNXGjC77OoEdkOo3sWd9sfXWpMiualLEcyCcp4YaKMcBGfqEn4JAtKMkwr1hmmTNvRQ6uNZwpP38xdtaNTwVnnX00lsEUOQDw';

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stripe Test',
      home: const PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Future<String> createPaymentIntent() async {
    final response = await http.post(
      //Uri.parse('http://10.0.2.2:8000/create-payment-intent'), Solo cuando se usa el emulador.
      Uri.parse('http://localhost:8000/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': 2000}),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo crear el PaymentIntent');
    }

    final data = jsonDecode(response.body);

    return data['client_secret'];
  }

  Future<void> makePayment() async {
    try {
      final clientSecret = await createPaymentIntent();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Stripe Test',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pago realizado correctamente!')),
      );
    } on StripeException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pago cancelado o rechazado: ${e.error.localizedMessage}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago de prueba')),
      body: Center(
        child: ElevatedButton(
          onPressed: makePayment,
          child: const Text('Pagar \$20 USD'),
        ),
      ),
    );
  }
}
