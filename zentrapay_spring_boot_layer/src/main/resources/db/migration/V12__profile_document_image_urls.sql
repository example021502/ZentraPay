-- ============================================================
-- V12: Hosted (ImgBB) URL columns for the Tier-2 KYC documents,
-- alongside the local-disk paths added in V11. See DocumentsService /
-- UploadImageToImgBBB — the local path stays the source of truth for
-- retrieve(), the URL is the hosted copy handed back to clients.
-- ============================================================
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS id_document_front_image_url VARCHAR(500);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS id_document_back_image_url VARCHAR(500);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS selfie_image_url VARCHAR(500);
