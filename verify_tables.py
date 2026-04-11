#!/usr/bin/env python3
import psycopg2

try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='peci',
        password='1234',
        database='peci_db'
    )
    cursor = conn.cursor()
    
    # Listar TODAS as tabelas
    cursor.execute('''
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema='public'
        ORDER BY table_name
    ''')
    
    all_tables = cursor.fetchall()
    learning_tables = [t[0] for t in all_tables if 'Learning' in t[0]]
    
    print("📋 TABELAS NA BD:\n")
    for t in all_tables:
        print(f"   {t[0]}")
    
    print(f"\n🔍 TABELAS DE LEARNING PATH ENCONTRADAS: {len(learning_tables)}")
    if learning_tables:
        for t in learning_tables:
            print(f"   ✅ {t}")
    else:
        print("   ❌ Nenhuma tabela de Learning Path")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Erro: {e}")
    import traceback
    traceback.print_exc()
