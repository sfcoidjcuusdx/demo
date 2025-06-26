import SwiftUI
import PhotosUI

struct ScreenshotGalleryView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 10)

                Image("LOGO 2-2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 340)
                    .shadow(color: .cyan.opacity(0.9), radius: 40)
                    .padding(.bottom, 10)

                Text("We're not done yet.\nBut we can still help.")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Submit a screenshot of your Screen Time below.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    showImagePicker = true
                }) {
                    Text("Submit Screenshot")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(
                                    LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )
                        .padding(.horizontal, 40)
                }
                .padding(.top, 10)

                // Screenshot Preview Section
                if !selectedImages.isEmpty {
                    Text("Submitted Screenshots")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.headline)
                        .padding(.top)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(9/16, contentMode: .fit)
                                    .frame(width: 120)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button("Done") {
                        for image in selectedImages {
                            uploadToImgBB(image: image, apiKey: "4c796235a7b78ffeda9139024d045525") { result in
                                switch result {
                                case .success(let url):
                                    print("✅ Uploaded screenshot to: \(url)")
                                case .failure(let error):
                                    print("❌ Upload failed:", error.localizedDescription)
                                }
                            }
                        }
                        showConfirmation = true
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
                    .padding(.top)
                }

                Spacer()
                Text("Thank you for supporting Loopless.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
            }
            .padding(.top)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView { image in
                if let image = image {
                    selectedImages.append(image)
                }
            }
        }
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Submitted"),
                message: Text("Your screenshots have been uploaded."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func uploadToImgBB(image: UIImage, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "InvalidImage", code: 0, userInfo: nil)))
            return
        }

        let base64Image = imageData.base64EncodedString()
        let url = URL(string: "https://api.imgbb.com/1/upload?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "image=\(base64Image)"
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let imageUrl = dataDict["url"] as? String {
                    completion(.success(imageUrl))
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

