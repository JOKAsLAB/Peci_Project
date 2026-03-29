import os
from pathlib import Path
import torch 
from langchain_community.document_loaders import PyMuPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from dotenv import load_dotenv
class PDFIndexer:

    DEFAULT_DB_PATH = "./chroma_db_gemma"
    DEFAULT_COLLECTION_NAME = "conhecimento_geral"
    CHUNK_SIZE = 800
    CHUNK_OVERLAP = 150

    def __init__(self, device="cuda"):
        load_dotenv("keys.env")
        gemma_token = os.getenv("TOKEN_GEMMA")
        if not gemma_token:
            raise ValueError("TOKEN_GEMMA não definida no ambiente.")
        
        os.environ["HF_TOKEN"] = gemma_token
        
        self.db_path = self.DEFAULT_DB_PATH
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

    def indexar_total(self, pdf_path, uc_id, ficheiro_id):
        path_obj = Path(pdf_path)
        if not path_obj.exists():
            print(f"Erro: Ficheiro não encontrado: {pdf_path}")
            return

        
  
        loader = PyMuPDFLoader(str(path_obj))
        pages = loader.load()
        
        chunks_para_guardar = []
        for p in pages:
            num_pag = p.metadata["page"] + 1
            page_chunks = self._splitter.split_documents([p])
            
            for chunk in page_chunks:
            
                nome_livro = path_obj.name
                chunk.page_content = f"title: {nome_livro} | text: {chunk.page_content}"
                
                chunk.metadata = {
                    "ficheiro_id": str(ficheiro_id), 
                    "nome_ficheiro": nome_livro,
                    "uc_id": str(uc_id),
                    "pagina": num_pag
                }
                chunks_para_guardar.append(chunk)

        if chunks_para_guardar:
            # HNWS Cosine é o recomendado para modelos Gemma
            Chroma.from_documents(
                documents=chunks_para_guardar,
                embedding=self.embeddings,
                persist_directory=self.db_path,
                collection_name=self.collection_name,
                collection_metadata={"hnsw:space": "cosine"} 
            )
            print(f"{path_obj.name} guardado com sucesso!")
        
        return {"status": "ok", "id": ficheiro_id, "file": path_obj.name}

if __name__ == "__main__":

    indexer = PDFIndexer(device="cuda")
    
    biblioteca = [
        #("./biblio/patterson_book.pdf", 42545, 1),
        #("./biblio/2006_WakerlyDDP_4ed.pdf", 40332, 2),
        #("./biblio/2017_Deschamps_Valderrama_Teres_DigitalSystems.pdf", 40332, 3),
        #("./biblio/free_range_vhdl.pdf", 40333, 4),
        ("./biblio/book.pdf", 40333, 5)
    ]

    for p, uc, f_id in biblioteca:
        try:
            indexer.indexar_total(p, uc, f_id)
        except Exception as e:
            print(f"Erro ao processar {p}: {e}")