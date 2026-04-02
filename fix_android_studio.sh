#!/bin/bash
# Android Studio JRE Hatalarını Düzeltme Scripti

echo "Android Studio sorunları gideriliyor..."

# 1. Android Studio cache ve config temizliği
echo "1. Android Studio önbelleği temizleniyor..."
rm -rf ~/.cache/Google/AndroidStudio*
rm -rf ~/.cache/JetBrains/AndroidStudio*

# 2. Android Studio ayarları yedekleniyor ve temizleniyor
echo "2. Android Studio ayarları yedekleniyor..."
if [ -d ~/.config/Google/AndroidStudio* ]; then
    cp -r ~/.config/Google/AndroidStudio* ~/AndroidStudio_config_backup_$(date +%Y%m%d_%H%M%S)
fi

# 3. Gradle daemon'u durdur ve önbelleği temizle
echo "3. Gradle daemon durdurulup önbellek temizleniyor..."
./gradlew --stop
rm -rf ~/.gradle/caches/
rm -rf ~/.gradle/daemon/
rm -rf ~/.gradle/wrapper/

# 4. Proje içi build ve cache klasörlerini temizle
echo "4. Proje build klasörleri temizleniyor..."
cd /home/admin/StudioProjects/stubstreet
rm -rf build/
rm -rf android/build/
rm -rf android/app/build/
rm -rf android/.gradle/
rm -rf .gradle/

# 5. Android Studio için önerilen VM seçenekleri
echo "5. Android Studio VM ayarları yapılandırılıyor..."
cat > ~/android_studio_custom_vm_options.txt << 'EOF'
# Bellek ayarları
-Xms512m
-Xmx4096m
-XX:ReservedCodeCacheSize=512m
-XX:MaxMetaspaceSize=1024m

# JXBrowser sorunları için
-Djxbrowser.disable=true
-Djna.nosys=true
-Djna.noclasspath=true

# Performans ayarları
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/tmp
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+ParallelRefProcEnabled
-XX:+DisableExplicitGC

# Hata ayıklama
-XX:ErrorFile=/home/admin/java_error_studio_%p.log
EOF

echo "VM ayarları ~/android_studio_custom_vm_options.txt dosyasına kaydedildi"

# 6. Swap alanını kontrol et ve artır
echo "6. Swap alanı kontrol ediliyor..."
free -h
sudo swapon --show

# 7. Android Studio'yu güvenli modda başlatma komutu
echo "7. Android Studio'yu güvenli modda başlatmak için:"
echo "   /opt/android-studio-for-platform/bin/studio.sh --disable-third-party-plugins"

echo ""
echo "Tamamlandı! Öneriler:"
echo "1. Android Studio'yu kapatın"
echo "2. Bu scripti çalıştırın: bash fix_android_studio.sh"
echo "3. VM ayarlarını uygulayın:"
echo "   - Android Studio'da: Help > Edit Custom VM Options"
echo "   - ~/android_studio_custom_vm_options.txt içeriğini yapıştırın"
echo "4. Android Studio'yu güvenli modda başlatın"
echo "5. Proje senkronizasyonunu yeniden yapın"
