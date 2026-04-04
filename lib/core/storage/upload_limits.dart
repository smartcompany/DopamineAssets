/// 커뮤니티·프로필 이미지/GIF 업로드 상한(바이트).
/// 업로드는 Supabase 서명 URL로 직접 PUT 하므로 Vercel 4.5MB 한도와 무관.
const int kCommunityImageUploadMaxBytes = 5 * 1024 * 1024;
