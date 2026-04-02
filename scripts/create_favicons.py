#!/usr/bin/env python3
"""
Farklı boyutlarda favicon'lar oluşturmak için script
"""

import os
from PIL import Image

def create_favicons():
    """Farklı boyutlarda favicon'lar oluştur"""
    
    # Giriş dosya yolu
    input_path = 'assets/images/logo_yazisiz.png'
    
    # Çıkış dosya yolları ve boyutları (büyütülmüş)
    favicon_sizes = [
        (24, 'web/favicon-16x16.png'),  # 16'dan 24'e büyütüldü
        (48, 'web/favicon-32x32.png'),  # 32'den 48'e büyütüldü
        (64, 'web/favicon-48x48.png'),  # 48'den 64'e büyütüldü
        (256, 'web/favicon.png'),       # 192'den 256'ya büyütüldü
    ]
    
    # Logo dosyasının varlığını kontrol et
    if not os.path.exists(input_path):
        print(f"❌ Logo dosyası bulunamadı: {input_path}")
        return False
    
    try:
        # Logo dosyasını aç
        img = Image.open(input_path)
        
        # RGBA moduna çevir (eğer değilse)
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Web klasörünün varlığını kontrol et
        if not os.path.exists('web'):
            print("❌ Web klasörü bulunamadı")
            return False
        
        success_count = 0
        
        # Her boyut için favicon oluştur
        for size, output_path in favicon_sizes:
            try:
                # Resmi yeniden boyutlandır
                resized = img.resize((size, size), Image.Resampling.LANCZOS)
                
                # Favicon olarak kaydet
                resized.save(output_path)
                
                print(f"✅ Favicon oluşturuldu: {output_path} ({size}x{size})")
                success_count += 1
                
            except Exception as e:
                print(f"❌ Hata ({size}x{size}): {e}")
        
        print(f"\n🎉 {success_count}/{len(favicon_sizes)} favicon başarıyla oluşturuldu!")
        return success_count > 0
        
    except Exception as e:
        print(f"❌ Genel hata: {e}")
        return False

if __name__ == "__main__":
    success = create_favicons()
    if success:
        print("🎉 Favicon'lar başarıyla oluşturuldu!")
    else:
        print("💥 Favicon oluşturma işlemi başarısız!")
