-- Inspect Schema
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_name IN ('vendor_profiles', 'vendor_services')
ORDER BY 
    table_name, ordinal_position;
