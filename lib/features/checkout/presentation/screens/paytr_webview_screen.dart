// lib/features/checkout/presentation/screens/paytr_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaytrWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> params; // PayTR form parametreleri

  const PaytrWebViewScreen({super.key, required this.params});

  @override
  State<PaytrWebViewScreen> createState() => _PaytrWebViewScreenState();
}

class _PaytrWebViewScreenState extends State<PaytrWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    
    // Debug: PayTR parametrelerini logla
    debugPrint('🔍 PayTR WebView Parameters:');
    widget.params.forEach((key, value) {
      if (key != 'paytr_token') { // Token'ı loglama
        debugPrint('  $key: $value');
      }
    });
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
            debugPrint('🌐 PayTR Page started: $url');
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
            debugPrint('✅ PayTR Page finished: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔄 PayTR Navigation: ${request.url}');
            
            // PayTR callback URL'lerini kontrol et
            if (request.url.contains('payment-success')) {
              debugPrint('✅ PayTR Payment Success');
              Navigator.of(context).pop('success');
              return NavigationDecision.prevent;
            } else if (request.url.contains('payment-failed')) {
              debugPrint('❌ PayTR Payment Failed');
              Navigator.of(context).pop('failed');
              return NavigationDecision.prevent;
            } else if (request.url.contains('paytr.com') && request.url.contains('error')) {
              debugPrint('⚠️ PayTR Error URL: ${request.url}');
              Navigator.of(context).pop('error');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ PayTR WebView Error: ${error.description}');
          },
        ),
      );

    // PayTR ödeme formunu POST ile açmak için bir HTML formu oluşturuyoruz
    final html = _buildAutoPostHtml(widget.params);
    _controller.loadHtmlString(html, baseUrl: 'https://www.paytr.com/odeme');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayTR Ödeme')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  String _buildAutoPostHtml(Map<String, dynamic> p) {
    // PayTR'a POST edilecek gizli alanlar
    final hiddenInputs = p.entries.map((e) {
      final key = e.key;
      final value = e.value is String ? e.value as String : e.value.toString();
      return '<input type="hidden" name="$key" value="${_escape(value)}" />';
    }).join();

    // Kart bilgileri kullanıcıdan alınır ve aynı form ile PayTR'a direkt POST edilir
    return '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>PayTR Ödeme</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Fira Sans", "Droid Sans", "Helvetica Neue", Arial, sans-serif; margin: 0; padding: 16px; background:#fff; color:#111; }
      .container { max-width: 520px; margin: 0 auto; }
      h1 { font-size: 18px; margin: 0 0 12px; }
      .hint { font-size: 13px; color:#444; background:#f7f7f9; border:1px solid #eee; padding:12px; border-radius:8px; margin-bottom:12px; }
      .row { display:flex; gap:12px; }
      .field { margin-bottom: 12px; width:100%; }
      label { display:block; font-size:13px; margin-bottom:6px; color:#222; }
      input { width:100%; box-sizing:border-box; padding:12px; font-size:16px; border:1px solid #d1d5db; border-radius:8px; outline:none; }
      input:focus { border-color:#3b82f6; box-shadow:0 0 0 3px rgba(59,130,246,.15); }
      button { width:100%; padding:14px; font-size:16px; border:none; border-radius:10px; color:#fff; background:#2563eb; }
      button:active { transform: translateY(1px); }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>PayTR Ödeme</h1>
      <div class="hint">
        Test için örnek kartlar: 9792030394440796, 4355084355084358, 5406675406675403<br>
        CVV: 000 • SKT: herhangi gelecekte bir tarih
      </div>
      <form method="post" action="https://www.paytr.com/odeme">
        $hiddenInputs
        <div class="field">
          <label>Kart Sahibi (cc_owner)</label>
          <input name="cc_owner" autocomplete="cc-name" placeholder="Ad Soyad" required>
        </div>
        <div class="field">
          <label>Kart Numarası (card_number)</label>
          <input name="card_number" inputmode="numeric" pattern="[0-9]{16,19}" autocomplete="cc-number" placeholder="XXXX XXXX XXXX XXXX" required>
        </div>
        <div class="row">
          <div class="field">
            <label>Ay (expiry_month)</label>
            <input name="expiry_month" inputmode="numeric" pattern="^(0?[1-9]|1[0-2])\$" placeholder="MM" required>
          </div>
          <div class="field">
            <label>Yıl (expiry_year)</label>
            <input name="expiry_year" inputmode="numeric" pattern="^[0-9]{2}\$" placeholder="YY" required>
          </div>
          <div class="field">
            <label>CVV</label>
            <input name="cvv" inputmode="numeric" pattern="^[0-9]{3}\$" placeholder="000" required>
          </div>
        </div>
        <button type="submit">PayTR ile Öde</button>
      </form>
    </div>
  </body>
</html>
''';
  }

  String _escape(String v) => v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}


