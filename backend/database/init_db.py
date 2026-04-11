#!/usr/bin/env python3
"""
Initialize PECI Project Database

Script que:
1. Cria todas as tabelas do schema.sql (via SQLAlchemy)
2. Verifica se as novas tabelas (Learning_Path, Learning_Path_Exercise) existem
3. Corre dados iniciais se necessário

Execute este script DEPOIS de:
- Ter PostgreSQL a rodar
- Ter o BD "peci_project" criado
- Ter o arquivo .env configurado com credentials
"""

import asyncio
import sys
from pathlib import Path

# Adiciona o diretório pai ao path para imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import engine, get_session
from app.models import Base


async def init_database():
    """Inicializa o BD criando todas as tabelas."""
    print("\n" + "=" * 70)
    print("PECI PROJECT — Database Initialization")
    print("=" * 70 + "\n")
    
    try:
        # 1. Criar todas as tabelas (se não existirem)
        print("🔧 Criando tabelas (se ainda não existirem)...")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("   ✅ Tabelas criadas/verificadas com sucesso\n")
        
        # 2. Verificar tabelas específicas
        print("📋 Verificando tabelas do Learning Path...")
        async with get_session() as session:
            # Tenta fazer uma query simples para confirmar
            result = await session.execute(
                "SELECT table_name FROM information_schema.tables WHERE table_schema='public'"
            )
            tables = [row[0] for row in result.fetchall()]
            
            expected_tables = ['Learning_Path', 'Learning_Path_Exercise']
            for table in expected_tables:
                if table in tables:
                    print(f"   ✅ Tabela '{table}' existe")
                else:
                    print(f"   ❌ Tabela '{table}' NÃO encontrada!")
        
        print("\n" + "=" * 70)
        print("✅ DATABASE INITIALIZATION COMPLETE")
        print("=" * 70)
        print("\nPodes agora:")
        print("  1. Correr o backend: cd backend && python -m uvicorn app.main:app --reload")
        print("  2. Testar API: python test_api_learning_paths.py")
        print("  3. Testar frontend: cd admin_docente && npm run dev")
        print("=" * 70 + "\n")
        
        return True
    
    except Exception as e:
        print(f"\n❌ ERRO durante inicialização:")
        print(f"   {type(e).__name__}: {e}")
        print("\n⚠️  Verificar:")
        print("   1. PostgreSQL está a rodar?")
        print("   2. BD 'peci_project' existe?")
        print("   3. Credenciais em .env estão corretas?")
        print("   4. Connection string no .env aponta para localhost?")
        return False


if __name__ == "__main__":
    success = asyncio.run(init_database())
    sys.exit(0 if success else 1)
