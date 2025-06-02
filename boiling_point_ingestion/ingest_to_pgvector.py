import os
import pandas as pd
from jinja2 import Environment, FileSystemLoader
from dotenv import load_dotenv
from langchain_core.documents import Document
from langchain_community.vectorstores.pgvector import PGVector
from langchain.embeddings.base import Embeddings

from granite_embedder import GraniteEmbedder

# LangChain-compatible wrapper for your embedder
class GraniteLangchainEmbedder(Embeddings):
    def __init__(self, granite_embedder):
        self.granite_embedder = granite_embedder

    def embed_documents(self, texts):
        return [list(vec) for vec in self.granite_embedder.embed_text(texts)]

    def embed_query(self, text):
        return list(self.granite_embedder.embed_text(text))

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL") or "postgresql+psycopg2://postgres:T8UQUIPiu#IZOZe3@34.174.7.160:5432/postgres?options=-csearch_path=boiling_point_vdb"
print(f"Using DATABASE_URL: {DATABASE_URL}")

def render_text(template_env, template_name, row):
    template = template_env.get_template(template_name)
    return template.render(row)

def main():
    embedder = GraniteEmbedder()
    lc_embedder = GraniteLangchainEmbedder(embedder)
    env = Environment(loader=FileSystemLoader("jinja_templates"))

    files_templates = {
        "data/Crop_recommendation.csv": "crop_recommendation.j2",
        "data/temperatures.csv": "temperature.j2",
        "data/ground_water_last5years.csv": "ground_water.j2"
    }

    chunk_size = 500  # Set your preferred batch size

    for file_name, template_name in files_templates.items():
        print(f"Processing {file_name} ...")
        df = pd.read_csv(file_name)

        for start in range(0, len(df), chunk_size):
            end = min(start + chunk_size, len(df))
            chunk = df.iloc[start:end]

            docs = []
            for _, row in chunk.iterrows():
                row_dict = row.to_dict()
                row_dict = {k: (None if pd.isna(v) else v) for k, v in row_dict.items()}
                if file_name == "data/ground_water_last5years.csv":
                    row_dict["Data_Acquisition_Time"] = row_dict.pop("Data Acquisition Time")
                    row_dict["Groundwater_Level_Quarterly_Manual_meter"] = row_dict.pop("Groundwater Level Quarterly Manual (meter)")
                text_rendered = render_text(env, template_name, row_dict)
                doc = Document(page_content=text_rendered, metadata=row_dict)
                docs.append(doc)

            PGVector.from_documents(
                documents=docs,
                embedding=lc_embedder,
                collection_name="boiling_point_vdb.final_data",
                connection_string=DATABASE_URL,
            )
            print(f"Inserted rows {start} to {end-1} from: {file_name}")

    print("All data ingested!")

if __name__ == "__main__":
    main()