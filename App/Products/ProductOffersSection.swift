import DinnertimeKit
import SwiftUI

/// The package sizes of a product, one line each with the shop that sells it, and the entry for another one below.
///
/// Swiping a line removes the offer; tapping it puts its values into the entry to correct them.
/// Offers of paused shops come last and are dimmed.
struct ProductOffersSection: View {
    @Bindable var model: ProductOffersModel
    /// Base unit of the product, which decides the units a size can be stated in.
    let unit: BaseUnit

    @State private var draft: OfferDraft
    /// Unit of the offer that was stored last in this section; `nil` until one was.
    @State private var lastUnit: OfferUnit?
    @Environment(HouseholdStore.self) private var household

    private let amounts = AmountFormatter()

    init(model: ProductOffersModel, unit: BaseUnit) {
        self.model = model
        self.unit = unit
        _draft = State(initialValue: OfferDraft(unit: OfferUnit(unit)))
    }

    var body: some View {
        Section("Packages and stores") {
            if model.hasOnlyPausedOffers {
                Text("Currently in no active store.")
                    .font(.footnote)
                    .foregroundStyle(.inkMuted)
            }
            ForEach(model.offers) { offer in
                Button {
                    edit(offer)
                } label: {
                    line(for: offer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .listRowBackground(draft.offerID == offer.id ? Color.accentSoft : Color.surface)
            }
            .onDelete(perform: delete)
            ProductOfferEntry(draft: $draft, stores: model.storeNames, units: OfferUnit.choices(for: unit), currencySymbol: prices.symbol, onSave: save)
                .listRowBackground(Color.sunken)
                .task {
                    await model.load()
                }
                .onChange(of: unit) {
                    lastUnit = nil
                    if !draft.unit.fits(unit) {
                        draft.unit = OfferUnit(unit)
                    }
                }
                .errorAlert($model.errorMessage)
        }
    }

    private var prices: PriceFormatter {
        PriceFormatter(currencyCode: household.currency)
    }

    /// An empty entry for a size sold everywhere, with the unit that was used last here.
    private var newDraft: OfferDraft {
        OfferDraft(unit: lastUnit ?? OfferUnit(unit))
    }

    /// The offer in one line; one of a paused shop is dimmed and says so.
    @ViewBuilder
    private func line(for offer: ProductOffer) -> some View {
        let text = offer.text(amounts: amounts, prices: prices)
        if offer.isStoreActive {
            Text(verbatim: text)
        } else {
            Text("\(text) · paused")
                .foregroundStyle(.inkMuted)
        }
    }

    /// Puts the values of an offer into the entry, or empties the entry if they are there already.
    private func edit(_ offer: ProductOffer) {
        draft = draft.offerID == offer.id ? newDraft : OfferDraft(offer, baseUnit: unit, formatter: amounts)
    }

    private func save() {
        let saved = draft
        Task {
            if await model.save(saved, baseUnit: unit) {
                lastUnit = saved.unit
                draft = saved.offerID == nil ? OfferDraft(store: saved.storedStore ?? "", unit: saved.unit) : newDraft
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let removed = offsets.map { model.offers[$0] }
        if removed.contains(where: { $0.id == draft.offerID }) {
            draft = newDraft
        }
        Task {
            for offer in removed {
                await model.delete(offer)
            }
        }
    }
}
