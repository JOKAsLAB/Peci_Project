#!/usr/bin/env python3
"""
Verifica se a BD tem o ENUM request_type_enum definido
e lista todos os ENUMs que existem na BD.
"""

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
    
    print("📋 VERIFICANDO ENUMS NA BD...\n")
    
    # Listar todos os ENUMs
    cursor.execute('''
        SELECT t.typname, 
               string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder)
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        WHERE t.typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        GROUP BY t.typname
        ORDER BY t.typname
    ''')
    
    enums = cursor.fetchall()
    
    if enums:
        print("✅ ENUMS ENCONTRADOS NA BD:\n")
        for enum_name, enum_values in enums:
            print(f"📌 {enum_name}")
            print(f"   Valores: {enum_values}")
            print()
    else:
        print("❌ Nenhum ENUM encontrado")
    
    # Verificar especificamente se request_type_enum existe
    cursor.execute('''
        SELECT EXISTS (
            SELECT 1 FROM pg_type 
            WHERE typname = 'request_type_enum'
            AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        )
    ''')
    
    has_request_type = cursor.fetchone()[0]
    
    print("\n" + "="*60)
    if has_request_type:
        print("✅ request_type_enum EXISTE NA BD")
    else:
        print("❌ request_type_enum NÃO EXISTE NA BD")
    
    # Verificar a tabela Request para ver a coluna type
    cursor.execute('''
        SELECT column_name, data_type, udt_name
        FROM information_schema.columns
        WHERE table_name='request'
        ORDER BY ordinal_position
    ''')
    
    print("\n📊 ESTRUTURA DA TABELA 'request':\n")
    result = cursor.fetchall()
    if result:
        for col_name, data_type, udt_name in result:
            tipo = udt_name if udt_name and data_type == 'USER-DEFINED' else data_type
            print(f"   ✅ {col_name:20} {tipo}")
    else:
        print("   ❌ Tabela 'request' não encontrada")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Erro: {e}")
    import traceback
    traceback.print_exc()
