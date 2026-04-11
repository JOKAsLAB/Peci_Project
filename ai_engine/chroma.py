import os
import chromadb
from dotenv import load_dotenv

_dir = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(_dir, "keys.env"))

DB_PATH = os.path.join(_dir, "chroma_db")
COLLECTION_NAME = "conhecimento_geral"

client = chromadb.PersistentClient(path=DB_PATH)
collection = client.get_collection(COLLECTION_NAME)

print(f"\n📦 Total de chunks: {collection.count()}\n")

# Lista todos os ficheiros
results = collection.get(include=["metadatas"])
ficheiros = {}
for meta in results["metadatas"]:
    fid = meta.get("ficheiro_id", "?")
    nome = meta.get("nome_ficheiro", "?")
    ficheiros[fid] = nome

print("📁 Ficheiros disponíveis:")
for i, (fid, nome) in enumerate(ficheiros.items()):
    print(f"  [{i}] {nome} — ID: {fid}")

print()
escolha = input("ID do ficheiro a remover (ou 'nome' para pesquisar por nome): ").strip()

# Pesquisa por nome
if not any(escolha == fid for fid in ficheiros):
    matches = {fid: nome for fid, nome in ficheiros.items() if escolha.lower() in nome.lower()}
    if not matches:
        print("❌ Nenhum ficheiro encontrado.")
        exit()
    for fid, nome in matches.items():
        escolha = fid
        print(f"✅ Encontrado: {nome} — ID: {fid}")
        break

# Remove
to_delete = collection.get(where={"ficheiro_id": escolha})
if not to_delete["ids"]:
    print("❌ Nenhum chunk encontrado para este ID.")
else:
    confirm = input(f"Remover {len(to_delete['ids'])} chunks de '{ficheiros.get(escolha)}'? (s/n): ")
    if confirm.lower() == "s":
        collection.delete(ids=to_delete["ids"])
        print(f"✅ {len(to_delete['ids'])} chunks removidos com sucesso.")
    else:
        print("Cancelado.")