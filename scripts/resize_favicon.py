#!/usr/bin/env python3
"""
Favicon boyutunu küçültmek için basit script
"""

import os
import sys

def resize_favicon():
    """Favicon dosyasını 32x32 boyutuna küçült"""
    
    # Gerekli dosya yolları
    logo_path = 'assets/images/logo_yazisiz.png'
    favicon_path = 'web/favicon.png'
    
    # Logo dosyasının varlığını kontrol et
    if not os.path.exists(logo_path):
        print(f"❌ Logo dosyası bulunamadı: {logo_path}")
        return False
    
    # Web klasörünün varlığını kontrol et
    if not os.path.exists('web'):
        print("❌ Web klasörü bulunamadı")
        return False
    
    try:
        # Pillow kullanarak resmi yeniden boyutlandır
        from PIL import Image
        
        # Logo dosyasını aç
        img = Image.open(logo_path)
        
        # 32x32 boyutuna küçült
        resized = img.resize((32, 32), Image.Resampling.LANCZOS)
        
        # Favicon olarak kaydet
        resized.save(favicon_path)
        
        print(f"✅ Favicon başarıyla oluşturuldu: {favicon_path} (32x32)")
        return True
        
    except ImportError:
        print("❌ PIL (Pillow) modülü bulunamadı")
        print("Yüklemek için: pip install Pillow")
        return False
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

if __name__ == "__main__":
    success = resize_favicon()
    sys.exit(0 if success else 1)
