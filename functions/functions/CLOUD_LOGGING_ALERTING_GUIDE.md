# Cloud Logging ve Alerting Rehberi

Bu rehber, Firebase Functions ve Google Cloud Platform üzerinde monitor etmek için Logging ve Alerting işlemlerini nasıl yapılandıracağınızı açıklar.

## Başlarken

- **Firebase Console** ve **Google Cloud Console** üzerinde projelerinizin olması gerekmektedir.
- Firebase Functions projenizi Google Cloud Platform ile entegre ettiğinizden emin olun.

## Cloud Logging

Cloud Logging, uygulamanızın çalışmasını izleyebilmeniz için güçlü bir araçtır.
### Adımlar:
1. **Google Cloud Console**'a gidin.
2. **Logging** hizmetini seçin.
3. Log'larınızı görüntülemek için **Log Explorer**'a tıklayın.
4. Belirli olayları ve hataları izlemek için filtreler oluşturun.
5. Log girişinde detaylı bilgi için log seviyelerini (e.g., info, error) kullanın.

### Log Görüntüleme
- Logları **Log Explorer** veya **Cloud Shell** kullanarak inceleyebilirsiniz.

## Alerting

Uygulamanızın kritik durumlarını izlemek için alarmlar kurabilirsiniz.
### Adımlar:
1. Google Cloud Console'da **Monitoring** bölümünü açın.
2. **Alerting** sekmesi altında **Create Alert Policy**'ye tıklayın.
3. İlgili log girişlerine, metriklere veya hata kodlarına bağlı alarmlar tanımlayın.
4. Alarm tetikleme koşullarını ve bildirim kanallarını (e.g., Email, SMS) belirleyin.

### Örnek Alarm
- **CPU Usage** %80 üzerine çıkarsa uyarı gönder.
- **HTTP 500 hatası** fazla sayıda görülürse alarm ver.

## Entegrasyon

- Firebase Functions logger entegrasyonu yaparak, Google Cloud Logging üzerinde uygulamanızdaki hatalar ve özel loglar izlenebilir.

## Tavsiyeler

- Log ve alarm politikalarını düzenli olarak gözden geçirin.
- Bildirim kanallarınızın güncel ve doğru olduğundan emin olun.

Bu rehber, Cloud Logging ve Alerting sistemlerinizi etkin biçimde kullanarak uygulama performansını ve hataları izleyebilmeniz için gereken adımları sunmaktadır.
