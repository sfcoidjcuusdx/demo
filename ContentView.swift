import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showSubmissionConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 25) {
                    Spacer()

                    // Bigger Logo
                    Image("LOGO 2-2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)

                    Text("We're not done yet.\nBut we can still help.")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal)

                    Text("Please upload screenshots of your Screen Time so we can personalize your recovery plan.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal)

                    // Submit Screenshot Button
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
                    }
                    .padding(.horizontal, 40)

                    // Screenshots Preview Grid
                    if !selectedImages.isEmpty {
                        Text("Your Uploaded Screenshots")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
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

                        // DONE Button
                        Button(action: {
                            for image in selectedImages {
                                uploadToImgBB(image: image, apiKey: "4c796235a7b78ffeda9139024d045525") { result in
                                    switch result {
                                    case .success(let url):
                                        print("✅ Uploaded to ImgBB: \(url)")
                                    case .failure(let error):
                                        print("❌ Upload failed: \(error.localizedDescription)")
                                    }
                                }
                            }
                            showSubmissionConfirmation = true
                        }) {
                            Text("Done")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top)
                    }

                    Spacer()

                    Text("Thank you for supporting Loopless.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView { image in
                    if let image = image {
                        selectedImages.append(image)
                    }
                }
            }
            .alert(isPresented: $showSubmissionConfirmation) {
                Alert(
                    title: Text("Screenshots Submitted"),
                    message: Text("Your Screen Time screenshots have been received. Thank you!"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Upload to ImgBB
    func uploadToImgBB(image: UIImage, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "InvalidImage", code: 0, userInfo: nil)))
            return
        }

        let url = URL(string: "https://api.imgbb.com/1/upload?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

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
                    let raw = String(data: data, encoding: .utf8) ?? "No response"
                    print("❌ Invalid JSON: \(raw)")
                    completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

}

