from sentence_transformers import SentenceTransformer
import numpy as np

class GraniteEmbedder:
    def __init__(self, model_path="ibm-granite/granite-embedding-278m-multilingual"):
        self.model = SentenceTransformer(model_path)

    def embed_text(self, texts):
        """
        Generate embedding vector(s) for the given text or list of texts.
        Args:
            texts (str or list of str): Input text(s) to embed.
        Returns:
            np.ndarray: Embedding vector(s). 
                        Shape (n_texts, dim) if list, or (1, dim) if single text.
        """
        if isinstance(texts, str):
            texts = [texts]
        embeddings = self.model.encode(texts)
        return embeddings  # Always return as 2D array/list
