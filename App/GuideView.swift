import SwiftUI

struct GuideView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          VStack(alignment: .leading, spacing: 10) {
            StudioTag(title: "KATLA / BAŞLANGIÇ", color: StudioTheme.copper)
            Text("Düzlemden\nboyuta.").font(.system(.largeTitle, design: .rounded, weight: .light))
            Text("Kâğıdın potansiyelini keşfet.").foregroundStyle(StudioTheme.muted)
          }
          GuideStep(number: "01", title: "İzini bırak", text: "Blueprint üzerinde parmağınla veya Apple Pencil ile düz bir çizgi çiz. Çizgi ızgaraya oturur ve kâğıdın kenarlarına uzatılarak kat izine dönüşür.", symbol: "pencil.and.outline")
          GuideStep(number: "02", title: "Katla, biçim ver", text: "Sürgüyü 180°’den 90°’ye taşı. iPhone Duo’da menteşe eşleşmesini açıp cihazı fiziksel olarak katlayabilirsin.", symbol: "rectangle.3.group")
          GuideStep(number: "03", title: "Her açıdan incele", text: "3D modeli döndürmek için sürükle, yaklaşmak için iki parmağını kullan. Tel kafes görünümüyle yüzey geometrisini incele.", symbol: "cube.transparent")
          GuideStep(number: "04", title: "Fikrini yanında taşı", text: "Parametrelerden malzeme ve boyutları değiştir. OBJ ile 3D modeli, SVG ile kesim ve kat çizgilerini dışa aktar.", symbol: "square.and.arrow.up")
          VStack(alignment: .leading, spacing: 10) {
            Text("Dağ ve vadi").font(.headline)
            Text("Düz çizgi dağ katını, kesik çizgi ters yöndeki vadi katını gösterir. Bu stüdyo geometrik katlamayı simüle eder; kâğıt çarpışması ve malzeme fiziği hesaplanmaz.")
              .font(.subheadline).foregroundStyle(StudioTheme.muted)
          }.padding(20).background(StudioTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
      }.background(StudioTheme.background).navigationTitle("Rehber")
    }
  }
}

private struct GuideStep: View {
  var number: String
  var title: String
  var text: String
  var symbol: String
  var body: some View {
    HStack(alignment: .top, spacing: 17) {
      Text(number).font(.caption.monospaced()).foregroundStyle(StudioTheme.copper).padding(.top, 4)
      VStack(alignment: .leading, spacing: 9) {
        Label(title, systemImage: symbol).font(.headline)
        Text(text).font(.subheadline).foregroundStyle(StudioTheme.muted).lineSpacing(4)
      }
    }
  }
}
