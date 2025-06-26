//
//  ImageStore.swift
//  LooplessMeantime
//
//  Created by rafiq kutty on 6/25/25.
//


import UIKit

class ImageStore {
    static let shared = ImageStore()
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    func saveImage(_ image: UIImage) -> String? {
        let filename = "screenshot-\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }

        do {
            try data.write(to: url)
            return filename
        } catch {
            print("Save error:", error)
            return nil
        }
    }

    func loadImage(named filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    func deleteImage(named filename: String) {
        let url = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
