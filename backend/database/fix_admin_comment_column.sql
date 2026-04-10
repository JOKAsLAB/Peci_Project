-- Fix admin comment column name (should be admin_comment not admincomment)
ALTER TABLE request RENAME COLUMN admincomment TO admin_comment;
