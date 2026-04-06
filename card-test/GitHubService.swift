import UIKit

// MARK: - GitHub Issue Submission Service

enum GitHubService {

    // Fine-grained PAT with issues:write scope on drkm9743/CardioDS only.
    // Worst case: someone creates issues on a public repo (same as web UI).
    private static let token = "GITHUB_PAT_PLACEHOLDER"
    private static let repo  = "drkm9743/CardioDS"

    struct SubmissionResult {
        let success: Bool
        let message: String
        let issueURL: String?
    }

    // MARK: - Submit Custom Card

    static func submitCustomCard(name: String, image: UIImage) async -> SubmissionResult {
        guard let resized = resizeForCard(image),
              let jpegData = resized.jpegData(compressionQuality: 0.85) else {
            return SubmissionResult(success: false, message: L("custom_submit_error"), issueURL: nil)
        }

        let base64 = jpegData.base64EncodedString()
        let title = "Custom Card Submission: \(name)"
        let body = """
        ## Custom Card Submission

        | Field | Value |
        |-------|-------|
        | **Card Name** | \(name) |
        | **Issuer** | Custom |
        | **Country** | N/A |

        ### Card Image

        <details>
        <summary>Base64 JPEG (click to expand)</summary>

        ```
        \(base64)
        ```
        </details>

        ---
        *Submitted from CardioDS app*
        """

        return await createIssue(title: title, body: body, labels: ["custom-card"])
    }

    // MARK: - Submit Dumped Card

    static func submitDumpedCard(name: String, bundleName: String, date: String, image: UIImage) async -> SubmissionResult {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            return SubmissionResult(success: false, message: L("mycards_submit_read_error"), issueURL: nil)
        }

        let base64 = jpegData.base64EncodedString()
        let title = "Community Card Submission: \(bundleName)"
        let body = """
        ## Community Card Submission

        | Field | Value |
        |-------|-------|
        | **Card Name** | \(name) |
        | **Bundle Name** | \(bundleName) |
        | **Date Saved** | \(date) |

        ### Card Image

        <details>
        <summary>Base64 JPEG (click to expand)</summary>

        ```
        \(base64)
        ```
        </details>

        ---
        *Submitted from CardioDS app*
        """

        return await createIssue(title: title, body: body, labels: ["community-card"])
    }

    // MARK: - GitHub API

    private static func createIssue(title: String, body: String, labels: [String]) async -> SubmissionResult {
        guard token != "GITHUB_PAT_PLACEHOLDER" else {
            return SubmissionResult(
                success: false,
                message: L("github_token_missing"),
                issueURL: nil
            )
        }

        let url = URL(string: "https://api.github.com/repos/\(repo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CardioDS", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "labels": labels
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            return SubmissionResult(success: false, message: L("custom_submit_error"), issueURL: nil)
        }
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResp = response as? HTTPURLResponse else {
                return SubmissionResult(success: false, message: L("custom_submit_error"), issueURL: nil)
            }

            if httpResp.statusCode == 201 {
                // Parse issue URL from response
                var issueURL: String?
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let htmlURL = json["html_url"] as? String {
                    issueURL = htmlURL
                }
                return SubmissionResult(success: true, message: L("custom_submit_success"), issueURL: issueURL)
            } else if httpResp.statusCode == 401 || httpResp.statusCode == 403 {
                return SubmissionResult(success: false, message: L("github_token_invalid"), issueURL: nil)
            } else {
                return SubmissionResult(success: false, message: L("custom_submit_error"), issueURL: nil)
            }
        } catch {
            return SubmissionResult(success: false, message: "\(L("custom_submit_error")): \(error.localizedDescription)", issueURL: nil)
        }
    }

    // MARK: - Image Resize

    private static func resizeForCard(_ image: UIImage) -> UIImage? {
        let maxWidth: CGFloat  = 1024
        let maxHeight: CGFloat = 640

        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let widthRatio  = maxWidth  / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio, 1.0) // never upscale

        if ratio >= 1.0 { return image } // already small enough

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
