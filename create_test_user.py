#!/usr/bin/env python3
"""
Cria um utilizador professor de teste para os testes de API.
Email: professor@test.com
Password: 123456
"""

import psycopg2
from passlib.context import CryptContext

# Usar exatamente o mesmo contexto que o backend
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Hash uma password com bcrypt (igual ao backend)."""
    return pwd_context.hash(password)

try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        user='peci',
        password='1234',
        database='peci_db'
    )
    cursor = conn.cursor()
    
    print('🔐 Criando utilizador Professor de teste...\n')
    
    # Gerar UUID
    import uuid
    prof_id = str(uuid.uuid4())
    
    # Hash da password com passlib (igual ao backend)
    password = "123456"
    password_hash = hash_password(password)
    
    # Inserir Base_User
    cursor.execute('''
        INSERT INTO Base_User (ID_User, Name, Email, Password_Hash, Role, Status)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT(Email) DO NOTHING
    ''', (
        prof_id,
        'Professor Teste',
        'professor@test.com',
        password_hash,
        'Professor',
        'Active'
    ))
    
    # Inserir Professor
    cursor.execute('''
        INSERT INTO Professor (ID_Professor, Department, Office, Short_Bio)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT(ID_Professor) DO NOTHING
    ''', (
        prof_id,
        'Departamento de TI',
        'Sala 101',
        'Professor para testes'
    ))
    
    conn.commit()
    print('✅ Utilizador criado com sucesso!')
    print(f'   Email: professor@test.com')
    print(f'   Password: 123456')
    print(f'   Role: Professor')
    print(f'   ID: {prof_id}')
    
    # Associar professor a uma UC (para poder criar caminhos)
    cursor.execute('SELECT ID_UC FROM Course_Unit LIMIT 1')
    uc_result = cursor.fetchone()
    
    if uc_result:
        uc_id = uc_result[0]
        cursor.execute('''
            INSERT INTO Professor_UC (ID_Professor, ID_UC)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
        ''', (prof_id, uc_id))
        conn.commit()
        print(f'\n✅ Professor associado à UC {uc_id}')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Erro: {e}')
    import traceback
    traceback.print_exc()
