#!/usr/bin/env python3
import psycopg2

try:
    conn = psycopg2.connect(
        host='localhost',
        user='peci',
        password='1234',
        database='peci_db'
    )
    cur = conn.cursor()
    
    # Get professor ID
    cur.execute("SELECT id_user FROM base_user WHERE email = %s", ('professor@test.com',))
    result = cur.fetchone()
    
    if result:
        professor_id = result[0]
        print(f"\n✅ Professor ID: {professor_id}\n")
        
        # Now add the professor_uc relationship
        cur.execute(
            "INSERT INTO professor_uc (id_professor, id_uc) VALUES (%s, %s) ON CONFLICT DO NOTHING",
            (professor_id, 40332)
        )
        conn.commit()
        print(f"✅ Added professor {professor_id} to UC 40332\n")
    else:
        print("❌ Professor not found")
    
    conn.close()
except Exception as e:
    print(f"❌ Error: {e}")
