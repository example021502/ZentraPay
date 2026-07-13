-- ============================================
-- Database Migration: External Recipients Table
-- Description: Creates table for storing Paystack recipient information
-- Author: ZentraPay Team
-- Created: 2026-06-07
-- ============================================

-- Create external_recipients table
-- This table stores recipient information for external bank transfers via Paystack

CREATE TABLE IF NOT EXISTS external_recipients (
    -- Primary key
    id SERIAL PRIMARY KEY,
    
    -- User who added this recipient
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Recipient details
    name VARCHAR(255) NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    bank_code VARCHAR(50) NOT NULL,
    bank_name VARCHAR(255),
    
    -- Paystack specific fields
    paystack_recipient_code VARCHAR(255) UNIQUE NOT NULL,
    
    -- Metadata
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for faster queries
    CONSTRAINT unique_user_recipient UNIQUE(user_id, account_number, bank_code)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_external_recipients_user_id 
    ON external_recipients(user_id);
    
CREATE INDEX IF NOT EXISTS idx_external_recipients_paystack_code 
    ON external_recipients(paystack_recipient_code);
    
CREATE INDEX IF NOT EXISTS idx_external_recipients_created_at 
    ON external_recipients(created_at);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_external_recipients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_external_recipients_updated_at
    BEFORE UPDATE ON external_recipients
    FOR EACH ROW
    EXECUTE FUNCTION update_external_recipients_updated_at();

-- Add comment to table
COMMENT ON TABLE external_recipients IS 'Stores external payment recipients for Paystack transfers';
COMMENT ON COLUMN external_recipients.paystack_recipient_code IS 'Unique recipient code from Paystack API';

-- ============================================
-- Sample Data (Optional - for testing)
-- ============================================
-- INSERT INTO external_recipients (user_id, name, account_number, bank_code, bank_name, paystack_recipient_code)
-- VALUES 
--     (1, 'John Doe', '1234567890', 'GHANBANK', 'Ghana Bank', 'RCP_123456789'),
--     (1, 'Jane Smith', '0987654321', 'ECOBANK', 'Ecobank Ghana', 'RCP_987654321');