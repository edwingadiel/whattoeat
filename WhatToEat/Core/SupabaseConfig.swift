import Foundation

struct SupabaseConfiguration {
    let url: URL
    let anonKey: String

    static func load(bundle: Bundle = .main) -> SupabaseConfiguration? {
        guard
            let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        else {
            return nil
        }

        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmedURL.isEmpty,
            !trimmedKey.isEmpty,
            !trimmedKey.contains("REPLACE_WITH_LOCAL_ANON_KEY"),
            let url = URL(string: trimmedURL)
        else {
            return nil
        }

        return SupabaseConfiguration(url: url, anonKey: trimmedKey)
    }
}
