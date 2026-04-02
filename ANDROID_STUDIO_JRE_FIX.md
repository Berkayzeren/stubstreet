# Android Studio JRE Çökme Sorunu Çözüm Rehberi

## Sorun Özeti
Android Studio'da JXBrowser IPC Server Thread'inde SIGABRT hatası alıyorsunuz. Bu genellikle şu nedenlerden kaynaklanır:

1. **Bellek yetersizliği** (Out of Memory)
2. **JXBrowser uyumsuzluğu**
3. **Bozuk cache/config dosyaları**

## Hızlı Çözüm Adımları

### 1. Android Studio'yu Kapatın
Tüm Android Studio pencerelerini kapatın.

### 2. Temizleme Script'ini Çalıştırın
```bash
cd /home/admin/StudioProjects/stubstreet
bash fix_android_studio.sh
```

### 3. Android Studio VM Ayarlarını Güncelleyin
1. Android Studio'yu açın
2. **Help → Edit Custom VM Options** menüsüne gidin
3. Aşağıdaki ayarları ekleyin:

```
-Xms512m
-Xmx4096m
-XX:ReservedCodeCacheSize=512m
-XX:MaxMetaspaceSize=1024m
-Djxbrowser.disable=true
```

### 4. Güvenli Modda Başlatma
Eğer sorun devam ederse:
```bash
/opt/android-studio-for-platform/bin/studio.sh --disable-third-party-plugins
```

### 5. Alternatif Çözümler

#### A. Swap Alanını Artırın
```bash
# Mevcut swap'ı kontrol et
free -h

# 8GB swap dosyası oluştur
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### B. Android Studio'yu Yeniden Yükleyin
1. Mevcut kurulumu kaldırın
2. En son sürümü [JetBrains Toolbox](https://www.jetbrains.com/toolbox-app/) üzerinden yükleyin

#### C. JDK Sürümünü Değiştirin
Android Studio ayarlarında:
- **File → Project Structure → SDK Location**
- JDK 17 veya JDK 21'in farklı bir sürümünü deneyin

### 6. Proje Bazlı Çözümler

#### gradle.properties Dosyasını Güncelleyin
```properties
# Gradle daemon bellek ayarları
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true

# Kotlin daemon bellek ayarları
kotlin.daemon.jvmargs=-Xmx4096m
```

### 7. Sistem Kaynaklarını İzleyin
```bash
# CPU ve bellek kullanımını izle
htop

# Android Studio process'lerini kontrol et
ps aux | grep studio
ps aux | grep java
```

## Kalıcı Çözüm

1. **Sistem RAM'ini artırın** (minimum 16GB önerilir)
2. **SSD kullanın** (disk I/O performansı için)
3. **Android Studio ayarlarını optimize edin**
4. **Gereksiz eklentileri devre dışı bırakın**

## Hata Tekrarlarsa

1. `/home/admin/java_error_studio_*.log` dosyalarını kontrol edin
2. Android Studio log dosyalarını inceleyin: `~/.config/Google/AndroidStudio*/system/log/`
3. `dmesg` komutuyla sistem loglarını kontrol edin

## Destek
- [Android Studio Issue Tracker](https://issuetracker.google.com/issues/new?component=192708)
- [JetBrains Support](https://youtrack.jetbrains.com/issues/JBR)
