/// Supabase project credentials — filled in during the backend connect step.
///
///   • [supabaseUrl]     = "Project URL"   (e.g. https://abcd.supabase.co)
///   • [supabaseAnonKey] = "anon public" / publishable key
///
/// Kept here (without the package) so the schema + plan stay in the repo while
/// the `supabase_flutter` package is re-added during the connect phase — its
/// native Android deps need a Gradle artifact download we'll warm up then.
const String supabaseUrl = '';
const String supabaseAnonKey = '';

/// True once real credentials are filled in above.
bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
