-- Fix missing request_type column in Request table
ALTER TABLE request ADD COLUMN request_type VARCHAR(20) NOT NULL DEFAULT 'other';
