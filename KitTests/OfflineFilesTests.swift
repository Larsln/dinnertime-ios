import Foundation
import Testing
@testable import MealplannerKit

/// Images and waiting links on disk.
struct OfflineFilesTests {
    @Test func imagesAreKeptByAddressAndPruned() {
        let store = ImageStore(directory: OfflineSupport.directory())
        let first = "http://meals.example.org/storage/covers/1-small.jpg"
        let second = "http://meals.example.org/storage/covers/2.jpg"
        store.store(Data([1, 2, 3]), for: first)
        store.store(Data([4]), for: second)

        #expect(store.data(for: first) == Data([1, 2, 3]))
        #expect(store.contains(second))
        #expect(!store.contains("http://meals.example.org/storage/covers/3.jpg"))

        store.prune(keeping: [second])

        #expect(store.data(for: first) == nil)
        #expect(store.data(for: second) == Data([4]))

        store.wipe()

        #expect(!store.contains(second))
    }

    @Test func fileNamesDoNotDependOnTheShapeOfTheAddress() {
        let name = ImageStore.fileName(for: "pending-cover/ABC.jpg")

        #expect(name.count == 64)
        #expect(name.allSatisfy { $0.isHexDigit })
        #expect(name != ImageStore.fileName(for: "pending-cover/ABD.jpg"))
    }

    @Test func coversReferToThumbnailsFirst() async throws {
        let store = try await OfflineSupport.syncedStore()
        let addresses = await store.imageAddresses

        #expect(addresses.first?.hasSuffix("-small.jpg") == true)
        #expect(addresses.contains("http://localhost:8000/storage/covers/95-pmpdpjcc1d.jpg"))
        #expect(addresses.count == Set(addresses).count)
    }

    @Test func aCoverThatWaitsIsShownUnderItsOwnAddress() async throws {
        let store = try await OfflineSupport.syncedStore()
        let recipe = try #require(await store.answer(RecipeEndpoints.uploadCover(id: 98, jpeg: Data([1])))).response
        let entry = try #require(await store.pendingChanges.first)

        #expect(recipe.summary.coverURL?.relativeString == entry.pendingCoverAddress)
        #expect(recipe.summary.coverThumbURL?.relativeString == entry.pendingCoverAddress)
        #expect(await store.imageAddresses.contains(entry.pendingCoverAddress))
    }

    @Test func linksWaitInOrderWithoutDuplicates() throws {
        let links = PendingLinks(directory: OfflineSupport.directory())
        let first = try #require(URL(string: "https://www.tiktok.com/@cook/video/1"))
        let second = try #require(URL(string: "https://example.org/recipe"))
        links.add(first)
        links.add(second)
        links.add(first)

        #expect(links.links.map(\.url) == [second, first])

        links.remove(second)

        #expect(links.links.map(\.url) == [first])

        links.removeAll()

        #expect(links.links.isEmpty)
    }
}
