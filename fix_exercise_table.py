#!/usr/bin/env python3
import psycopg2

try:
    # Conectar ao database peci_db
    conn = psycopg2.connect(
        host='localhost', port=5432,
        user='peci',
        password='1234',
        database='peci_db'
    )
    conn.set_isolation_level(0)  # Autocommit mode
    cursor = conn.cursor()
    
    print('🔧 Alterando proprietário da tabela exercise...')
    
    # Esta solução contorna o problema mudando o proprietário
    cursor.execute("ALTER TABLE exercise OWNER TO peci")
    
    print('✅ Proprietário alterado')
    
    # Agora adicionar a coluna
    cursor.execute('''
        ALTER TABLE exercise
        ADD COLUMN IF NOT EXISTS published BOOLEAN NOT NULL DEFAULT false
    ''')
    
    print('✅ Coluna published adicionada!')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Erro: {e}')
    import traceback
    traceback.print_exc()
