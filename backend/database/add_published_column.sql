SELECT 
    ID_Exercise,
    ID_UC,
    Topic_Name,
    Question,
    Type,
    Difficulty,
    jsonb_pretty(Solution) AS solution_json,
    jsonb_array_length(Solution->'options') AS num_options,
    Published
FROM Exercise
WHERE 
    Solution IS NULL 
    OR (Solution->'options' IS NULL)
    OR jsonb_array_length(Solution->'options') = 0
ORDER BY ID_UC, Topic_Name;