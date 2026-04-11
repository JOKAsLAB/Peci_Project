import os
import fitz
from pathlib import Path
import torch
from langchain_community.document_loaders import PyMuPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from dotenv import load_dotenv
from typing import BinaryIO, Optional, Dict, Any
import uuid


class PDFIndexer:

    _BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    DEFAULT_DB_PATH = os.path.join(_BASE_DIR, "chroma_db")
    DEFAULT_COLLECTION_NAME = "conhecimento_geral"
    DEFAULT_UPLOAD_DIR = os.path.join(_BASE_DIR, "uploads")
    CHUNK_SIZE = 800
    CHUNK_OVERLAP = 150

    def __init__(self, device="cuda", db_path: str = DEFAULT_DB_PATH, upload_dir: str = DEFAULT_UPLOAD_DIR):
        _dir = os.path.dirname(os.path.abspath(__file__))
        load_dotenv(os.path.join(_dir, "keys.env"))

        gemma_token = os.getenv("TOKEN_GEMMA")
        groq_key = os.getenv("GROQ_API_KEY")

        if not gemma_token:
            raise ValueError("TOKEN_GEMMA não definida no ambiente.")
        if not groq_key:
            raise ValueError("GROQ_API_KEY não definida no ambiente.")

        os.environ["HF_TOKEN"] = gemma_token
        os.environ["GROQ_API_KEY"] = groq_key

        self.db_path = db_path
        self.upload_dir = Path(upload_dir)
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        self.collection_name = self.DEFAULT_COLLECTION_NAME

        model_kwargs = {
            "device": device,
            "trust_remote_code": True,
            "model_kwargs": {"torch_dtype": torch.float32}
        }

        self.embeddings = HuggingFaceEmbeddings(
            model_name="google/embeddinggemma-300m",
            model_kwargs=model_kwargs,
            encode_kwargs={'normalize_embeddings': True}
        )

        self._splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.CHUNK_SIZE,
            chunk_overlap=self.CHUNK_OVERLAP
        )

    def extrair_indice(self, pages):
        pdf_path = pages[0].metadata.get("source", "")
        doc = fitz.open(pdf_path)
        toc = doc.get_toc(simple=False)
        doc.close()

        if toc:
            capitulos = []
            for item in toc:
                if item[0] in [1, 2]:
                    capitulos.append({
                        "titulo": item[1].strip(),
                        "nivel": item[0],
                        "pagina_pdf": item[2]
                    })

            if capitulos:
                print(f"TOC extraido: {len(capitulos)} entradas")
                return sorted(capitulos, key=lambda x: x["pagina_pdf"])

        print("PDF sem TOC. Chunks guardados sem capítulo.")
        return []

    def mapear_capitulo(self, pagina_pdf, capitulos):
        if not capitulos:
            return "", ""

        cap_atual = "Front Matter"
        sub_atual = ""
        for cap in capitulos:
            if pagina_pdf >= cap["pagina_pdf"]:
                if cap["nivel"] == 1:
                    cap_atual = cap["titulo"]
                    sub_atual = ""
                else:
                    sub_atual = cap["titulo"]
            else:
                break
        return cap_atual, sub_atual

    def salvar_ficheiro(self, file_content: BinaryIO | bytes, original_filename: str, ficheiro_id: str) -> tuple[str, Path]:
        """
        Salva um ficheiro no diretório de uploads.
        
        Args:
            file_content: Conteúdo do ficheiro (bytes ou arquivo aberto)
            original_filename: Nome original do ficheiro
            
        Returns:
            (nome_salvo, caminho_completo)
        """
        file_ext = Path(original_filename).suffix
        unique_filename = f"{ficheiro_id}{file_ext}"
        file_path = self.upload_dir / unique_filename
        
        # Guardar ficheiro
        try:
            with open(file_path, "wb") as f:
                if isinstance(file_content, bytes):
                    f.write(file_content)
                else:
                    f.write(file_content.read())
            
            print(f"✅ Ficheiro guardado: {file_path}")
            return original_filename, file_path
        except Exception as e:
            print(f"❌ Erro ao guardar ficheiro: {e}")
            raise

    def indexar_com_upload(self, file_content: BinaryIO | bytes, original_filename: str, uc_id: int, ficheiro_id: Optional[str] = None) -> Dict[str, Any]:

        if not ficheiro_id:
            ficheiro_id = str(uuid.uuid4())
        
        try:

            nome_salvo, file_path = self.salvar_ficheiro(file_content, original_filename,ficheiro_id)
            

            resultado = self.indexar_total(str(file_path), uc_id, ficheiro_id)
            
     
            resultado["file_path"] = str(file_path)
            resultado["original_name"] = nome_salvo
            
            return resultado
        except Exception as e:

            raise

    def indexar_total(self, pdf_path, uc_id, ficheiro_id, original_filename=None):
        path_obj = Path(pdf_path)
        if not path_obj.exists():
            print(f"Erro: Ficheiro não encontrado: {pdf_path}")
            return

        loader = PyMuPDFLoader(str(path_obj))
        pages = loader.load()

        capitulos = self.extrair_indice(pages)

        nome_livro = original_filename or path_obj.name  # ← usa o nome original

        chunks_para_guardar = []
        for p in pages:
            num_pag_pdf = p.metadata["page"] + 1
            capitulo, subcapitulo = self.mapear_capitulo(num_pag_pdf, capitulos)
            page_chunks = self._splitter.split_documents([p])

            for chunk in page_chunks:
                chunk.page_content = f"title: {nome_livro} | text: {chunk.page_content}"
                chunk.metadata = {
                    "ficheiro_id": str(ficheiro_id),
                    "nome_ficheiro": nome_livro,
                    "uc_id": str(uc_id),
                    "pagina": num_pag_pdf,
                    "capitulo": capitulo,
                    "subcapitulo": subcapitulo
                }
                chunks_para_guardar.append(chunk)

        if chunks_para_guardar:
            Chroma.from_documents(
                documents=chunks_para_guardar,
                embedding=self.embeddings,
                persist_directory=self.db_path,
                collection_name=self.collection_name,
                collection_metadata={"hnsw:space": "cosine"}
            )
            print(f"{nome_livro} guardado com sucesso!")

        return {"status": "ok", "id": ficheiro_id, "file": nome_livro}
    
    def remover_ficheiro(self, ficheiro_id: str):
        collection = self.vectorstore._collection if hasattr(self, 'vectorstore') else None
        
        # Abre a collection diretamente
        import chromadb
        client = chromadb.PersistentClient(path=self.db_path)
        collection = client.get_collection(self.collection_name)
        
        # Remove todos os chunks com este ficheiro_id
        results = collection.get(where={"ficheiro_id": ficheiro_id})
        if results["ids"]:
            collection.delete(ids=results["ids"])
            print(f"✅ {len(results['ids'])} chunks removidos do ChromaDB para ficheiro_id={ficheiro_id}")
        else:
            print(f"⚠️ Nenhum chunk encontrado para ficheiro_id={ficheiro_id}")

'''
if __name__ == "__main__":
    indexer = PDFIndexer(device="cuda")

    biblioteca = [
        ("./biblio/patterson_book.pdf", 42545, 1),
        ("./biblio/2006_WakerlyDDP_4ed.pdf", 40332, 2),
        ("./biblio/2017_Deschamps_Valderrama_Teres_DigitalSystems.pdf", 40332, 3),
        ("./biblio/free_range_vhdl.pdf", 40333, 4),
        ("./biblio/book.pdf", 42545, 5)
    ]

    for p, uc, f_id in biblioteca:
        try:
            indexer.indexar_total(p, uc, f_id)
        except Exception as e:
            print(f"Erro ao processar {p}: {e}")
'''