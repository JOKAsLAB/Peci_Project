DELETE FROM base_user
WHERE email IN ('joaobastos707@gmail.com', 'joaocbpinho2004@gmail.com')
RETURNING email, role;
