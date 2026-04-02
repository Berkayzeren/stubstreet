// lib/features/legal/legal_texts.dart
//
// Purpose:
// - Centralize long-form legal documents (User Agreement, Privacy Policy, KVKK Notice)
//   as immutable string constants so UI widgets can render them in scrollable dialogs.
//
// Why keep them in code (instead of raw assets) during development?
// - Easier iteration and code review: changes are tracked by VCS side-by-side with UI logic
// - Immediate availability without asset bundling pitfalls
// - Later, you can swap this to remote-config or CMS-backed content
//
// Teaching note:
// - Keep legal content separated from UI widgets to avoid huge widget files and improve readability.
// - Provide a single source of truth to prevent mismatches across different screens.

// Comprehensive User Agreement (Kapsamlı Kullanıcı Sözleşmesi)
const String kUserAgreement = '''
1. KAPSAMLI KULLANICI SÖZLEŞMESİ
Bilet Sokağı Platformu Detaylı Kullanıcı Sözleşmesi ve Genel Şartlar

Yürürlük Tarihi: 20.09.2025

MADDE 1: TARAFLAR VE TANIMLAR

1.1. Taraflar: İşbu Kullanıcı Sözleşmesi (“Sözleşme”), [Şirketinizin Tam Ticari Unvanı] adresinde mukim [Şirketinizin Adresi] ("Bilet Sokağı" veya "Aracı Hizmet Sağlayıcı") ile www.biletsokagi.com web sitesi ve Bilet Sokağı mobil uygulamalarından ("Platform") faydalanan kullanıcı ("Kullanıcı") arasında, Kullanıcı'nın Platform'u kullanmaya başlamasıyla birlikte elektronik ortamda kurulmuş ve yürürlüğe girmiştir.

1.2. Tanımlar:

Platform: www.biletsokagi.com alan adı ve alt alan adları ile buna bağlı Bilet Sokağı mobil uygulamalarının bütününü ifade eder.

Kullanıcı: Platform'a üye olan ve/veya hizmetlerden faydalanan, Alıcı ve/veya Satıcı sıfatını haiz olabilecek her bir gerçek veya tüzel kişiyi ifade eder.

Alıcı: Platform üzerinde Satıcı tarafından satışa arz edilen Bilet'i, Platform'un sunduğu altyapıyı kullanarak satın alan Kullanıcı'yı ifade eder.

Satıcı: Mülkiyetinde veya tasarrufunda bulunan Bilet'i, Platform'un sunduğu altyapıyı kullanarak satışa arz eden Kullanıcı'yı ifade eder.

Bilet: Konser, spor müsabakası, tiyatro, festival, seminer gibi ücretli ve belirli bir tarihte gerçekleşen etkinliklere katılım hakkı tanıyan, fiziki veya elektronik, birinci el veya ikinci el belgeyi ifade eder.

Hizmet: Bilet Sokağı'nın, Kullanıcılar'ın kendi aralarındaki Bilet alım satım sözleşmelerini kurabilmeleri için bir sanal pazar yeri ortamı sağladığı, Türk Borçlar Kanunu kapsamında "simsarlık" ve 6563 sayılı Kanun kapsamında "aracılık" hizmetlerini ifade eder.

Hizmet Bedeli (Komisyon): Satıcı tarafından gerçekleştirilen başarılı bir Bilet satışı işlemi üzerinden, Bilet Sokağı'nın belirlediği ve Platform'da ilan ettiği oranda, Satıcı'dan tahsil edilecek olan aracılık hizmeti ücretini ifade eder.

MADDE 2: SÖZLEŞMENİN KONUSU VE PLATFORMUN HUKUKİ NİTELİĞİ

2.1. Sözleşmenin Konusu: İşbu Sözleşme, Kullanıcı'nın Platform'dan faydalanma koşullarını, tarafların hak ve yükümlülüklerini ve Bilet Sokağı'nın aracılık hizmetinin sınırlarını düzenlemektedir.

2.2. Bilet Sokağı'nın Hukuki Niteliği ve Sorumsuzluğu: Bilet Sokağı; etkinlik düzenleyen (organizatör), Bilet'in ilk satıcısı, seyahat acentesi (1618 sayılı Kanun kapsamında), bilet distribütörü veya alım satım sözleşmesinin tarafı değildir. Bilet Sokağı'nın yegane rolü, Satıcı ile Alıcı'yı bir araya getiren bir teknoloji platformu sağlamaktır. Alım satıma ilişkin nihai sözleşme, münhasıran Alıcı ile Satıcı arasında kurulur. Bilet Sokağı, bu sözleşmenin ifasından, Bilet'in içeriğinden, gerçekliğinden veya etkinliğin kendisinden sorumlu tutulamaz.

MADDE 3: ÜYELİK VE KULLANIM ŞARTLARI

3.1. Üyelik: Kullanıcı, Platform'a üye olurken sunduğu tüm bilgilerin (ad, soyad, e-posta, telefon, T.C. Kimlik Numarası, banka bilgileri vb.) doğru, güncel ve kendisine ait olduğunu, bu bilgilerin sahteciliği önleme ve güvenliği sağlama amacıyla kullanılmasını kabul ettiğini beyan ve taahhüt eder. Bilgilerdeki değişiklikleri güncellemek Kullanıcı'nın sorumluluğundadır.

3.2. Hesap Güvenliği: Kullanıcı, şifresi ve hesap bilgilerinin gizliliğinden ve güvenliğinden bizzat sorumludur. Hesabının izinsiz kullanıldığını fark etmesi halinde derhal Bilet Sokağı'nı bilgilendirmekle yükümlüdür.

3.3. Yasaklı Faaliyetler: Kullanıcı, aşağıdaki faaliyetlerde bulunmayacağını gayrikabili rücu olarak kabul eder:
* Sahte, çalıntı, taklit edilmiş, geçersiz veya kullanım hakkı devredilemeyen (isime özel, devredilemez vb.) Bilet listelemek.
* Fiyat manipülasyonu yapmak, kara para aklama girişiminde bulunmak.
* Diğer kullanıcıları taciz etmek, dolandırmak veya aldatıcı eylemlerde bulunmak.
* Platform'un altyapısına zarar verecek yazılımlar kullanmak, veri çekme (scraping) veya tersine mühendislik yapmak.

MADDE 4: ALICI VE SATICILARIN ÖZEL YÜKÜMLÜLÜKLERİ

4.1. Satıcı'nın Hak ve Yükümlülükleri:

Biletin Mülkiyeti ve Gerçekliği: Satıcı, listelediği Bilet'in yasal sahibi olduğunu, Bilet'in gerçek, geçerli ve kullanılabilir olduğunu, üzerinde üçüncü kişilerin herhangi bir hakkı veya bir takyidat bulunmadığını garanti eder.

Doğru Bilgi Sağlama: Satıcı, Bilet'in tüm özelliklerini (etkinlik, tarih, yer, blok, sıra, koltuk, varsa kısıtlamalar vb.) hiçbir şüpheye yer bırakmayacak şekilde, doğru ve eksiksiz olarak ilan açıklamasında belirtmekle yükümlüdür.

Fiyatlandırma: Bilet fiyatını belirleme yetkisi tamamen Satıcı'ya aittir. Ancak Bilet Sokağı, fahiş fiyatlandırma veya manipülatif eylemlere karşı listelemeyi kaldırma hakkını saklı tutar.

Teslimat ve Sorumluluk: Satıcı, başarılı satışın ardından Bilet'i Alıcı'ya Bilet Sokağı'nın belirlediği yöntem ve süreler içinde (genellikle platform üzerinden elektronik transfer) eksiksiz olarak teslim etmekle yükümlüdür. Teslimat tamamlanana kadar tüm sorumluluk Satıcı'ya aittir.

İptal ve İade: Etkinliğin organizatör tarafından iptal edilmesi durumunda, Satıcı, Alıcı'dan gelen iade talebini kabul etmek ve Bilet Sokağı'nın bu kapsamda yapacağı para iadesi sürecine uymak zorundadır. Satıcı tarafından listelenen Bilet'in sahte veya geçersiz olduğunun tespiti halinde, Satıcı, Alıcı'ya ödenen tüm bedeli ve Bilet Sokağı'nın uğrayacağı tüm zararları (komisyon kaybı, itibar zedelenmesi vb.) karşılamakla yükümlüdür.

Vergi Sorumluluğu: Satıcı, Platform üzerinden gerçekleştirdiği satışlardan elde ettiği tüm gelirler için doğacak her türlü vergi, resim ve harçtan bizzat kendisinin sorumlu olduğunu kabul eder.

4.2. Alıcı'nın Hak ve Yükümlülükleri:

Araştırma Yükümlülüğü: Alıcı, Bilet satın almadan önce etkinliğin resmi koşullarını, mekan kurallarını, yaş sınırı gibi detayları ve Satıcı'nın ilan açıklamasını dikkatle okumakla yükümlüdür.

İkinci El Bilet Riski: Alıcı, özellikle ikinci el Bilet alımlarında, Bilet'in orijinal satış koşulları (örn: sadece fan kulüp üyelerine özel, isme özel vb.) nedeniyle etkinliğe girişte sorun yaşanması gibi potansiyel risklerin var olduğunu anladığını ve bu riski üstlendiğini kabul eder. Bilet Sokağı, etkinliğe sorunsuz girişi garanti etmez.

Kontrol ve Bildirim: Alıcı, teslim aldığı Bilet'in ilanda belirtilen özelliklerle uyuşup uyuşmadığını derhal kontrol etmek ve herhangi bir uyuşmazlık durumunda Bilet Sokağı'nın belirlediği süre içinde bildirimde bulunmakla yükümlüdür.

MADDE 5: ÖDEME SÜRECİ VE HİZMET BEDELİ

5.1. Güvenli Ödeme Sistemi: Alıcı, Bilet bedelini doğrudan Satıcı'ya değil, Bilet Sokağı'nın kontrolündeki güvenli hesaba öder. Bilet Sokağı, Alıcı'nın Bilet'i sorunsuz teslim aldığını teyit etmesini veya etkinliğin sorunsuz gerçekleşmesini takiben, belirlediği sürenin sonunda, toplam bedelden kendi Hizmet Bedeli'ni (Komisyon) düştükten sonra kalan tutarı Satıcı'nın hesabına aktarır. Bu süreç, "emanet hesabı" (escrow) mantığıyla çalışır ve her iki tarafı da korumayı amaçlar.

5.2. Hizmet Bedeli: Bilet Sokağı, aracılık hizmeti karşılığında Satıcı'dan, Platform'da ilan edilen oran üzerinden Hizmet Bedeli tahsil etme hakkına sahiptir. Bilet Sokağı, bu oranları önceden haber vererek değiştirme hakkını saklı tutar.

MADDE 6: SORUMLULUĞUN SINIRLANDIRILMASI

Mevzuatın izin verdiği en geniş ölçüde, Bilet Sokağı, aşağıdaki durumlardan kaynaklanan doğrudan veya dolaylı hiçbir zarardan sorumlu tutulamaz:

Kullanıcılar tarafından sağlanan içeriğin, bilgilerin veya Bilet'lerin doğruluğu, kalitesi, güvenliği veya yasallığı.

Etkinliğin kalitesi, ertelenmesi, iptali, yer veya tarih değişikliği.

Alıcı'nın etkinliğe alınmaması veya etkinlikte yaşadığı herhangi bir olumsuz deneyim.

Alıcı ve Satıcı arasındaki her türlü iletişim, anlaşmazlık ve uyuşmazlık.

Platform'a erişimde yaşanabilecek teknik kesintiler, gecikmeler veya siber saldırılar.

Kullanıcı'nın vergi yükümlülüklerini yerine getirmemesi.

MADDE 7: SÖZLEŞMENİN FESHİ VE ASKIYA ALINMASI

Kullanıcı'nın işbu Sözleşme'ye veya Platform kurallarına aykırı hareket ettiğinin tespiti halinde, Bilet Sokağı, hiçbir bildirimde bulunmaksızın ve tazminat yükümlülüğü olmaksızın Kullanıcı'nın üyeliğini geçici olarak askıya alabilir veya kalıcı olarak sonlandırabilir.

MADDE 8: UYGULANACAK HUKUK VE YETKİLİ MAHKEME

İşbu Sözleşme'nin yorumlanmasında ve uygulanmasında Türkiye Cumhuriyeti Kanunları geçerlidir. Sözleşme'den doğacak her türlü uyuşmazlığın çözümünde Zonguldak (Ereğli) Mahkemeleri ve İcra Daireleri münhasıran yetkilidir.

MADDE 9: SON HÜKÜMLER

Bilet Sokağı, işbu Sözleşme'yi ve eklerini tek taraflı olarak, Platform üzerinden duyurmak suretiyle değiştirebilir. Değişiklikler, duyuru tarihinde yürürlüğe girer. Kullanıcı, Platform'u kullanmaya devam ederek bu değişiklikleri kabul etmiş sayılır.
''';

// Comprehensive Privacy Policy (Kapsamlı Gizlilik Politikası)
const String kPrivacyPolicy = '''
2. KAPSAMLI GİZLİLİK POLİTİKASI
(Bu belge, önceki versiyonun detaylandırılmış halidir ve yeterli kapsamdadır. Temel yapı ve içerik korunmuştur.)

Bilet Sokağı Detaylı Gizlilik Politikası

Son Güncelleme: 20.09.2025

[Şirket Unvanınız] ("Bilet Sokağı", "biz") olarak, kullanıcılarımızın (www.biletsokagi.com ve Bilet Sokağı mobil uygulaması - "Platform") gizliliğine ve kişisel verilerinin korunmasına en üst düzeyde önem vermekteyiz. Bu politika, hangi verileri topladığımızı, bu verileri hangi amaçlarla kullandığımızı, kimlerle paylaştığımızı ve bu konudaki yasal haklarınızı detaylı bir şekilde açıklamaktadır.

1. Topladığımız Kişisel Veri Kategorileri

Kimlik Bilgileri: Ad, soyad, T.C. Kimlik Numarası (yalnızca yasal doğrulama, faturalandırma ve sahteciliği önleme amaçlarıyla), doğum tarihi.

İletişim Bilgileri: E-posta adresi, cep telefonu numarası, adres bilgileri (gerekli durumlarda).

Finansal Veriler: Satıcılar için banka adı ve IBAN numarası, Alıcılar için ödeme işlemleri sırasında güvenli iş ortağımız tarafından işlenen ve tarafımızca sadece maskelenmiş (örn: **** **** **** 1234) olarak saklanan kredi kartı bilgileri.

İşlem Güvenliği ve Müşteri İşlem Verileri: Kullanıcı ID, işlem geçmişi (alınan/satılan biletler), işlem tutarı, alışveriş tarihi, kullanıcı yorumları, destek talepleri ve yazışmaları.

Pazarlama Verileri: Ticari elektronik ileti gönderimine izin vermiş kullanıcılar için pazarlama tercihleri.

Teknik ve Cihaz Verileri: IP adresi, MAC adresi, cihazın marka ve modeli, işletim sistemi, tarayıcı bilgileri, konum verisi (izninizle), Platform kullanım alışkanlıklarınız ve çerez kayıtları.

2. Verilerinizi Toplama Yöntemlerimiz ve Kullanım Amaçlarımız
Verilerinizi, Platform'a üye olurken, işlem yaparken doğrudan sizden veya Platform'u kullanımınız sırasında çerezler gibi teknolojiler aracılığıyla otomatik olarak toplarız. Bu verileri;

Sözleşmesel Yükümlülüklerimizi Yerine Getirmek: Üyeliğinizi oluşturmak, bilet alım satım işlemlerine aracılık etmek, ödemeleri güvenli bir şekilde işlemek ve paranızı hesabınıza aktarmak.

Yasal Yükümlülüklerimizi Yerine Getirmek: Vergi Usul Kanunu, E-Ticaretin Düzenlenmesi Hakkında Kanun gibi yasalara uymak ve yetkili makamların taleplerini karşılamak.

Meşru Menfaatlerimiz Doğrultusunda: Platform'un güvenliğini sağlamak (şüpheli işlem analizi, sahtecilik tespiti), hizmet kalitemizi ölçmek, kullanıcı şikayetlerini çözmek ve Platform'u teknik olarak geliştirmek.

Açık Rızanızla: Size özel kampanya, indirim ve pazarlama bildirimleri göndermek.

3. Verilerinizi Kimlerle ve Neden Paylaşıyoruz?
Kişisel verileriniz, açık rızanız olmaksızın veya yasal bir zorunluluk bulunmadıkça, hizmetin doğası gereği zorunlu olanlar dışında üçüncü taraflarla paylaşılmaz.

Ödeme Hizmeti Sağlayıcıları: Ödemelerinizi güvenli bir şekilde almak ve Satıcı'lara aktarmak için lisanslı ödeme kuruluşları ile.

Hizmet Sağlayıcılar ve İş Ortakları: Platform'un barındırılması (hosting), veri analizi, SMS/e-posta gönderimi gibi teknik hizmetleri aldığımız tedarikçiler ile.

Yetkili Kamu Kurum ve Kuruluşları: Mahkemeler, savcılıklar ve diğer devlet kurumları tarafından yasal olarak talep edilmesi halinde.

4. Veri Saklama Süresi
Kişisel verileriniz, ilgili yasal mevzuatta belirtilen saklama süreleri (örn: vergi kanunları için 5 yıl, ticaret kanunu için 10 yıl) veya verinin işlenme amacı için gerekli olan süre boyunca saklanır. Süre sonunda verileriniz silinir, yok edilir veya anonim hale getirilir.

5. Çocukların Gizliliği
Platform, 18 yaşından küçüklerin kullanımına yönelik değildir. 18 yaşından küçüklerden bilerek veri toplamadığımızı ve tespit etmemiz halinde bu verileri derhal sileceğimizi beyan ederiz.

6. Haklarınız ve İletişim
Kişisel verileriniz üzerindeki haklarınızı (bilgi talep etme, düzeltme, silme vb.) kullanmak için detaylı bilgiye KVKK Aydınlatma Metnimizden ulaşabilir ve taleplerinizi info@biletsokagi.com adresine gönderebilirsiniz.
''';

// KVKK Detailed Notice (Kapsamlı KVKK Aydınlatma Metni)
const String kKvkkNotice = '''
3. KAPSAMLI KVKK AYDINLATMA METNİ
(Bu belge, önceki versiyonun detaylandırılmış halidir ve yasal çerçeveye sıkı sıkıya bağlı olduğu için yapısı korunmuştur. İçerik zenginleştirilmiştir.)

KİŞİSEL VERİLERİN KORUNMASI KANUNU KAPSAMINDA DETAYLI AYDINLATMA METNİ

1. Veri Sorumlusu
İşbu aydınlatma metni, Veri Sorumlusu sıfatıyla hareket eden [Şirketinizin Tam Ticari Unvanı] (“Bilet Sokağı”) tarafından, 6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) uyarınca, Bilet Sokağı Kullanıcılarının bilgilendirilmesi amacıyla hazırlanmıştır.

2. Kişisel Verilerin İşlenme Amaçları, Hukuki Sebepleri ve Toplama Yöntemleri

Aşağıdaki tabloda, hangi kişisel verinizin, hangi hukuki sebebe dayanılarak, hangi amaçla işlendiği detaylandırılmıştır:

Veri Kategorisi	Örnek Veri	İşleme Amacı	KVKK Uyarınca Hukuki Sebep
Kimlik	Ad, Soyad, TCKN	Üyelik oluşturma, kullanıcı doğrulama, sahteciliği önleme, yasal bildirimler.	Sözleşmenin Kurulması ve İfası, Hukuki Yükümlülük, Meşru Menfaat
İletişim	E-posta, Telefon No	Bilgilendirme, işlem onayı, şifre yenileme, destek hizmetleri, (izinli) pazarlama.	Sözleşmenin Kurulması ve İfası, Meşru Menfaat, Açık Rıza
Finansal	IBAN (Satıcı), Maskelenmiş Kart Bilgisi (Alıcı)	Satış bedelinin aktarılması, ödeme işleminin gerçekleştirilmesi.	Sözleşmenin Kurulması ve İfası
Müşteri İşlem	Sipariş geçmişi, bilet detayları, destek talepleri	Sipariş yönetimi, uyuşmazlıkların çözümü, hizmet kalitesinin artırılması.	Sözleşmenin Kurulması ve İfası, Meşru Menfaat
Teknik Veri	IP Adresi, Cihaz ID	Sistem güvenliğinin sağlanması, hata tespiti, performans analizi.	Hukuki Yükümlülük (5651 S. Kanun), Meşru Menfaat

Kişisel verileriniz, Platform'a üye olurken/kullanırken tarafınızca sağlanan bilgiler ve Platform'u kullanımınız sırasında oluşan log kayıtları, çerezler gibi otomatik yöntemlerle toplanmaktadır.

3. Kişisel Verilerin Aktarılması
Kişisel verileriniz, KVKK’nın 8. ve 9. maddeleri uyarınca ve yukarıda belirtilen amaçlar doğrultusunda; ödeme süreçlerinin yürütülmesi için lisanslı ödeme hizmeti sağlayıcılarına, teknik altyapının sürdürülmesi için barındırma (hosting) ve bulut hizmeti alınan tedarikçilere ve yasal uyuşmazlıklar veya talepler halinde yetkili kamu kurum ve kuruluşları ile yargı mercilerine aktarılabilecektir.

4. İlgili Kişi Olarak Haklarınız (KVKK Madde 11)
Kanun’un 11. maddesi uyarınca veri sahibi olarak haklarınız şunlardır:

Kişisel verilerinizin işlenip işlenmediğini öğrenme,

İşlenmişse buna ilişkin bilgi talep etme,

İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,

Yurt içinde/dışında aktarıldığı üçüncü kişileri bilme,

Eksik/yanlış işlenmişse düzeltilmesini isteme,

KVKK Madde 7 çerçevesinde silinmesini/yok edilmesini isteme,

Düzeltme, silme, yok etme işlemlerinin aktarıldığı üçüncü kişilere bildirilmesini isteme,

Otomatik sistemler ile analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme,

Kanuna aykırı işlenmesi sebebiyle zarara uğramanız hâlinde zararın giderilmesini talep etme.

Başvuru:
Müftü Mahallesi Uğur Mumcu Caddesi Eski Toyota Binası K:2, D:16, 67300 Ereğli/Zonguldak
E-posta: info@biletsokagi.com
''';

// English versions for international users
// Teaching note:
// - Keep parity in structure with TR versions so UI sections align regardless of locale.
// - These are sample placeholders; your legal counsel should review and replace texts.
const String kUserAgreementEn = '''
1. COMPREHENSIVE USER AGREEMENT
Detailed User Agreement and General Terms for the StubStreet Platform

Effective Date: 2025-09-20

ARTICLE 1: PARTIES AND DEFINITIONS

1.1 Parties: This User Agreement ("Agreement") is electronically concluded between [Your Company Legal Name] located at [Your Company Address] ("StubStreet" or "Intermediary Service Provider") and the user ("User") who benefits from the website www.biletsokagi.com and the StubStreet mobile applications (the "Platform"), and enters into force when the User starts using the Platform.

1.2 Definitions:
Platform: The domain www.biletsokagi.com and its subdomains together with StubStreet mobile applications.
User: Any natural or legal person who becomes a member and/or benefits from the services on the Platform, who may act as Buyer and/or Seller.
Buyer: The User who purchases a Ticket listed by the Seller by using the Platform’s infrastructure.
Seller: The User who lists for sale a Ticket owned or controlled by them by using the Platform’s infrastructure.
Ticket: A physical or electronic, primary or secondary market document granting access to a paid event (concert, sports, theater, festival, seminar) held on a specific date.
Service: The brokerage/intermediation services under Turkish law by which StubStreet provides a marketplace for Users to conclude ticket sale/purchase agreements among themselves.
Service Fee (Commission): The intermediation fee charged to the Seller at the rate announced on the Platform for a successful sale.

ARTICLE 2: SCOPE AND LEGAL NATURE

2.1 Scope: This Agreement sets out the conditions for using the Platform, parties’ rights and obligations, and the boundaries of StubStreet’s intermediation.

2.2 Legal Nature and Disclaimer: StubStreet is not an organizer, original ticket seller, travel agency, ticket distributor, or a party to the sale contract. The final contract is solely between Buyer and Seller. StubStreet is not liable for the performance of that contract, the content or authenticity of the Ticket, or the event itself.

ARTICLE 3: MEMBERSHIP AND USE

3.1 Membership: The User declares all information provided (name, surname, email, phone, TR ID Number, bank info, etc.) is accurate, up to date, and belongs to them, and consents to its use for fraud prevention and security. The User must keep information updated.

3.2 Account Security: The User is solely responsible for the confidentiality and security of credentials. In case of unauthorized use, the User must promptly notify StubStreet.

3.3 Prohibited Activities: The User irrevocably agrees not to:
* List fake/stolen/forged/invalid or non-transferable tickets.
* Manipulate prices, attempt money laundering.
* Harass or defraud other users; engage in deceptive acts.
* Harm the Platform infrastructure, perform scraping or reverse engineering.

ARTICLE 4: SPECIAL OBLIGATIONS OF BUYERS AND SELLERS

4.1 Seller’s Obligations:
Ownership and Authenticity: Seller guarantees lawful ownership and validity/usability of the listed Ticket, free of third-party claims.
Accurate Information: Seller must disclose all ticket details (event, date, venue, block/row/seat, restrictions) precisely in the listing.
Pricing: Seller sets prices; StubStreet may remove listings for excessive pricing or manipulation.
Delivery and Responsibility: After a successful sale, Seller must deliver the Ticket within the methods and timeframes set by StubStreet (typically electronic transfer). Responsibility remains with the Seller until delivery is complete.
Cancellation and Refunds: If the event is canceled, the Seller must accept refunds and follow StubStreet’s refund process. If a ticket is determined fake/invalid, Seller must compensate the Buyer and all damages (including commission losses, reputational harm).
Taxes: Seller is solely responsible for all taxes/fees arising from their sales.

4.2 Buyer’s Obligations:
Due Diligence: Buyer must review official event terms, venue rules, age limits, and the listing details before purchasing.
Secondary Market Risks: Buyer accepts risks inherent to resale tickets (e.g., personalized/non-transferable tickets) and acknowledges StubStreet does not guarantee entry.
Inspection and Notice: Buyer must promptly check the delivered ticket and notify disputes within StubStreet’s specified period.

ARTICLE 5: PAYMENTS AND SERVICE FEE

5.1 Secure Payments: The Buyer pays into a secure account controlled by StubStreet, not directly to the Seller. After confirmed delivery/event completion, StubStreet remits the amount minus the Service Fee to the Seller (escrow model).

5.2 Service Fee: StubStreet may change the fee rates upon prior notice on the Platform.

ARTICLE 6: LIMITATION OF LIABILITY
To the maximum extent permitted by law, StubStreet is not liable for: user-provided content or ticket validity; event quality/postponement/cancellation/changes; denial of entry; any communications/disputes between Buyer and Seller; outages or cyberattacks; user’s tax noncompliance.

ARTICLE 7: TERMINATION/SUSPENSION
StubStreet may suspend or terminate membership without notice or compensation if the User violates this Agreement or Platform rules.

ARTICLE 8: GOVERNING LAW AND JURISDICTION
Turkish law applies. Zonguldak (Ereğli) Courts and Enforcement Offices have exclusive jurisdiction.

ARTICLE 9: FINAL PROVISIONS
StubStreet may unilaterally amend this Agreement via Platform notice; continued use constitutes acceptance.
''';

const String kPrivacyPolicyEn = '''
2. COMPREHENSIVE PRIVACY POLICY
(Expanded version; structure preserved. Sample text to be reviewed by counsel.)

StubStreet Detailed Privacy Policy
Last Updated: 2025-09-20

We value privacy and data protection. This policy explains what data we collect, why, with whom we share it, and your rights.

1. Data Categories
Identity: Name, surname, TR ID Number (for legal verification/invoicing/fraud prevention), date of birth.
Contact: Email, phone, address (where necessary).
Financial: IBAN (Sellers), masked card info (Buyers handled by PSP; StubStreet stores only masked form).
Security/Transaction: User ID, order history, amounts, dates, reviews, support interactions.
Marketing: Preferences for commercial emails (if consented).
Technical: IP, device/browser info, OS, location (with permission), cookies/usage analytics.

2. Collection and Use Purposes
Contract performance; legal compliance; legitimate interests (security, fraud detection, quality); and, with consent, marketing communications.

3. Sharing
With licensed payment providers; hosting/analytics/SMS-email vendors; and competent authorities upon lawful request.

4. Retention
Kept for statutory or purpose-based durations; then deleted or anonymized.

5. Minors
Platform is not intended for under 18; data is not knowingly collected and is removed if discovered.

6. Rights & Contact
You may request access, correction, deletion, objection, etc. Contact: info@biletsokagi.com
''';

const String kKvkkNoticeEn = '''
3. DETAILED KVKK NOTICE
(Expanded version aligned with Turkish KVKK. Sample translation.)

Data Controller: [Your Company Legal Name] ("StubStreet").

Purposes, Legal Bases, Methods:
- Identity (Name, Surname, TR ID): membership, verification, fraud prevention, notifications. Legal bases: contract, legal obligation, legitimate interest.
- Contact (Email, Phone): notifications, confirmations, support, (consented) marketing. Legal bases: contract, legitimate interest, consent.
- Financial (IBAN, masked card): payouts and payments. Legal basis: contract.
- Customer Transaction (orders, tickets, support): order management, dispute resolution, quality. Legal bases: contract, legitimate interest.
- Technical (IP, device ID): security, troubleshooting, performance. Legal bases: legal obligation (5651), legitimate interest.

Transfers: to PSPs, hosting/cloud vendors, and authorities/courts when legally required.

Rights (KVKK Art. 11): learn if processed, request info, purpose compliance, recipients, rectification, deletion, notification to recipients, object to profiling, claim damages.

Applications:
Address: Müftü Mahallesi Uğur Mumcu Caddesi Eski Toyota Binası K:2, D:16, 67300 Ereğli/Zonguldak
Email: info@biletsokagi.com
''';
