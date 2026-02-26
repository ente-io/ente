-- Add ADMIN role to collection share role enum
ALTER TYPE role_enum ADD VALUE IF NOT EXISTS 'ADMIN';
