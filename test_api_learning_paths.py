#!/usr/bin/env python3
# =============================================================
# PECI PROJECT — Learning Paths API Test Script
#
# Testa todos os endpoints de Learning Paths com dados reais.
# Requer que o backend esteja a rodar em http://127.0.0.1:8000
# =============================================================

import requests
import json
import sys
from typing import Optional

BASE_URL = "http://127.0.0.1:8000"
UC_ID = 1001  # UC que o professor tem acesso (ver create_test_user.py)

# Cria credenciais de teste
# Usa o professor criado em create_test_user.py
ADMIN_EMAIL = "professor@test.com"
ADMIN_PASSWORD = "123456"

# Token será obtido após login
TOKEN: Optional[str] = None


def auth_login() -> bool:
    """Autentica e obtém token JWT."""
    global TOKEN
    
    print("\n🔐 Fazendo login...")
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/auth/login",
            json={
                "email": ADMIN_EMAIL,
                "password": ADMIN_PASSWORD,
            },
            timeout=5
        )
        
        if response.status_code != 200:
            print(f"  ❌ Login falhou: {response.status_code}")
            print(f"     Resposta: {response.text[:200]}")
            return False
        
        data = response.json()
        TOKEN = data.get("access_token")
        
        if not TOKEN:
            print(f"  ❌ Nenhum token retornado")
            return False
        
        print(f"  ✅ Login bem-sucedido")
        print(f"     Token: {TOKEN[:50]}...")
        return True
    
    except requests.ConnectionError:
        print(f"  ❌ Não consegues conectar a {BASE_URL}")
        print("     Certifica-te que o backend está a rodar:")
        print("     cd backend/backend && python -m uvicorn app.main:app --reload")
        return False
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return False


def get_headers() -> dict:
    """Retorna headers com token de autenticação."""
    return {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json",
    }


def test_list_paths() -> Optional[str]:
    """Testa GET /learning-paths."""
    print("\n📋 Testando: GET /learning-paths")
    
    try:
        response = requests.get(
            f"{BASE_URL}/api/v1/professors/learning-paths",
            headers=get_headers(),
            timeout=5
        )
        
        if response.status_code != 200:
            print(f"  ❌ Status: {response.status_code}")
            print(f"     Resposta: {response.text[:200]}")
            return None
        
        data = response.json()
        print(f"  ✅ Encontrados {len(data)} caminhos")
        
        if len(data) > 0:
            first_path = data[0]
            print(f"     Primeiro: '{first_path.get('Name')}' (ID: {first_path.get('ID_Path')})")
            return first_path.get("ID_Path")
        
        return None
    
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return None


def test_create_path(name: str = "Teste Path Builder") -> Optional[str]:
    """Testa POST /learning-paths."""
    print(f"\n➕ Testando: POST /learning-paths (criar '{name}')")
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/professors/learning-paths?id_uc={UC_ID}",
            headers=get_headers(),
            json={
                "Name": name,
                "Description": "Caminho de teste criado por script",
                "Published": False,
            },
            timeout=5
        )
        
        if response.status_code != 201:
            print(f"  ❌ Status: {response.status_code}")
            print(f"     Resposta: {response.text[:200]}")
            return None
        
        data = response.json()
        path_id = data.get("ID_Path")
        print(f"  ✅ Caminho criado com sucesso")
        print(f"     ID: {path_id}")
        print(f"     Name: {data.get('Name')}")
        
        return path_id
    
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return None


def test_get_path(path_id: str) -> bool:
    """Testa GET /learning-paths/{id}."""
    print(f"\n📥 Testando: GET /learning-paths/{{id}}")
    
    try:
        response = requests.get(
            f"{BASE_URL}/api/v1/professors/learning-paths/{path_id}",
            headers=get_headers(),
            timeout=5
        )
        
        if response.status_code != 200:
            print(f"  ❌ Status: {response.status_code}")
            return False
        
        data = response.json()
        exercises = data.get("path_exercises", [])
        print(f"  ✅ Caminho obtido com sucesso")
        print(f"     Name: {data.get('Name')}")
        print(f"     Exercícios: {len(exercises)}")
        
        return True
    
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return False


def test_update_path(path_id: str) -> bool:
    """Testa PUT /learning-paths/{id}."""
    print(f"\n✏️  Testando: PUT /learning-paths/{{id}}")
    
    try:
        response = requests.put(
            f"{BASE_URL}/api/v1/professors/learning-paths/{path_id}",
            headers=get_headers(),
            json={
                "Name": "Caminho Atualizado",
                "Published": True,
            },
            timeout=5
        )
        
        if response.status_code != 200:
            print(f"  ❌ Status: {response.status_code}")
            return False
        
        data = response.json()
        print(f"  ✅ Caminho atualizado com sucesso")
        print(f"     Name: {data.get('Name')}")
        print(f"     Published: {data.get('Published')}")
        
        return True
    
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return False


def test_add_exercise(path_id: str, exercise_id: str, order: int = 1) -> bool:
    """Testa POST /learning-paths/{id}/exercises."""
    print(f"\n➕ Testando: POST /learning-paths/{{id}}/exercises")
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/professors/learning-paths/{path_id}/exercises",
            headers=get_headers(),
            json={
                "ID_Exercise": exercise_id,
                "Order_Num": order,
            },
            timeout=5
        )
        
        if response.status_code != 201:
            print(f"  ❌ Status: {response.status_code}")
            print(f"     Resposta: {response.text[:200]}")
            return False
        
        data = response.json()
        print(f"  ✅ Exercício adicionado com sucesso")
        print(f"     Posição: #{data.get('Order_Num')}")
        
        return True
    
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return False


def test_delete_path(path_id: str) -> bool:
    """Testa DELETE /learning-paths/{id}."""
    print(f"\n🗑️  Testando: DELETE /learning-paths/{{id}}")
    
    try:
        response = requests.delete(
            f"{BASE_URL}/api/v1/professors/learning-paths/{path_id}",
            headers=get_headers(),
            timeout=5
        )
        
        if response.status_code != 204:
            print(f"  ❌ Status: {response.status_code}")
            return False
        
        print(f"  ✅ Caminho deletado com sucesso")
        return True
    
    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return False


def get_first_exercise() -> Optional[str]:
    """Obtém o UUID do primeiro exercício da UC."""
    print("\n🔍 Buscando primeiro exercício...")
    
    try:
        response = requests.get(
            f"{BASE_URL}/api/v1/professors/exercises?id_uc={UC_ID}&limit=1",
            headers=get_headers(),
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            if isinstance(data, list) and len(data) > 0:
                exercise_id = data[0].get("id_exercise")
                print(f"  ✅ Exercício encontrado: {exercise_id}")
                return exercise_id
        
        # Fallback: usar exercício mock se nenhum for encontrado
        print(f"  ⚠️  Nenhum exercício encontrado, usando mock UUID")
        return "12345678-1234-1234-1234-123456789012"
    
    except Exception as e:
        print(f"  ⚠️  Erro ao buscar exercício: {e}")
        return "12345678-1234-1234-1234-123456789012"


def main():
    """Função principal."""
    print("\n" + "=" * 70)
    print("PECI PROJECT — Learning Paths API Test")
    print("=" * 70)
    
    # 1. Login
    if not auth_login():
        print("\n❌ Não consegueste autenticar. Abortar testes.")
        sys.exit(1)
    
    # 2. Testar endpoints
    print("\n" + "-" * 70)
    print("EXECUTANDO TESTES")
    print("-" * 70)
    
    # 2.1 Listar caminhos
    existing_path = test_list_paths()
    
    # 2.2 Criar novo caminho
    new_path = test_create_path("Teste API Script")
    if not new_path:
        print("\n❌ Não conseguiste criar caminho. Abortar testes.")
        sys.exit(1)
    
    # 2.3 Obter detalhes
    test_get_path(new_path)
    
    # 2.4 Atualizar
    test_update_path(new_path)
    
    # 2.5 Adicionar exercício
    exercise_id = get_first_exercise()
    if exercise_id:
        test_add_exercise(new_path, exercise_id, order=1)
    
    # 2.6 Deletar
    test_delete_path(new_path)
    
    # Resumo
    print("\n" + "=" * 70)
    print("✅ TESTES COMPLETOS!")
    print("=" * 70)
    print("Se todos os testes passaram com sucesso (✅), então:")
    print("  ✅ Backend está funcional")
    print("  ✅ Autenticação funciona")
    print("  ✅ Endpoints de Learning Paths funcionam")
    print("  ✅ BD está sincronizada com Models")
    print("\nPodes agora testar o Frontend:")
    print("  cd admin_docente && npm run dev")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Testes interrompidos pelo utilizador")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Erro crítico: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
