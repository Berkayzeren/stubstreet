// lib/core/utils/web_image.dart
//
// Purpose: Provide a tiny utility to make remote image URLs safer for Flutter Web.
// On Flutter Web, some CDNs (like Ticketmaster's s1.ticketm.net) may block cross-origin
// image requests or taint the canvas, which results in images failing to render or
// throwing network/CORS errors. To mitigate this without a backend proxy, we route image
// requests through a public, cache-friendly image proxy that sets proper CORS headers.
//
// Why images.weserv.nl?
// - It acts as a pass-through image cache with CORS enabled
// - It is widely used for client-side image proxying and supports HTTPS
// - We only use it on web targets to avoid any impact on mobile apps
//
// Usage:
//   final url = webSafeImageUrl(event.imageUrl);
//   Image.network(url)
//
// Notes:
// - The proxy expects plain host/path (no scheme). We strip https:// or http://.
// - If the incoming URL is already proxied or is a data URL, we return it as-is.

// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart' show kIsWeb;

/// Convert a remote image URL into a CORS-safe URL for Flutter Web.
///
/// @param originalUrl: The original image URL (e.g., "https://s1.ticketm.net/dam/...")
/// @returns String: A proxied URL when running on web; otherwise the original URL.
String webSafeImageUrl(String? originalUrl) {
  // If there's no URL, return an empty string so widgets can handle gracefully
  if (originalUrl == null || originalUrl.isEmpty) return '';

  final lower = originalUrl.toLowerCase();

  // Skip data URLs or already proxied URLs
  if (lower.startsWith('data:') || lower.contains('images.weserv.nl')) {
    return originalUrl;
  }

  // Skip Firebase Storage URLs - they have their own CORS handling and authentication tokens
  if (lower.contains('firebasestorage.googleapis.com')) {
    return originalUrl;
  }
  
  // Skip Unsplash URLs - they already support CORS and don't need proxying
  if (lower.contains('images.unsplash.com')) {
    return originalUrl;
  }

  // Known hosts that can fail TLS on some Android devices or block cross-origin on web
  // We proxy these on ALL platforms to improve reliability
  const hostsNeedingProxy = [
    's1.ticketm.net',
    'ticketm.net',
    'ticketmaster.com',
    // Universe (Ticketmaster brands) - bazı cihazlarda TLS/SSL hataları görüldü
    'images.universe.com',
  ];

  final shouldProxyForHost = hostsNeedingProxy.any((h) => lower.contains(h));
  final shouldProxy = kIsWeb || shouldProxyForHost;
  if (!shouldProxy) return originalUrl;

  // Normalize and strip scheme for the proxy (expects host/path)
  final withoutScheme = originalUrl
      .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
      .trim();

  // IMPORTANT: Encode as a single component so that any query string from the
  // original URL doesn't conflict with the proxy's own query parameters
  final encoded = Uri.encodeComponent(withoutScheme);

  // Build proxy URL with HTTPS explicitly
  // Docs: https://images.weserv.nl/
  final proxied = 'https://images.weserv.nl/?url=$encoded';
  return proxied;
}


