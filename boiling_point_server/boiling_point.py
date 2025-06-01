from langchain_ibm import WatsonxLLM
from langchain_community.llms import Replicate
from langchain_community.vectorstores.pgvector import PGVector
from langchain.prompts import PromptTemplate
from ibm_watson_machine_learning.metanames import GenTextParamsMetaNames as GenParams
from langchain.agents.output_parsers import JSONAgentOutputParser
from langchain.output_parsers import OutputFixingParser
from langchain_core.agents import AgentFinish
from langchain.schema.runnable import RunnableLambda
from langchain.agents import AgentExecutor
from langchain.tools import tool
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.prompts import PromptTemplate
from langchain_core.runnables import RunnableMap
from langchain.chains import LLMChain
from fastapi import FastAPI, HTTPException
from fastapi import UploadFile, File, Form
from typing import List
from pydantic import BaseModel
from jinja2 import Template
import json
import base64
from fastapi import File, UploadFile
import sqlalchemy
from sqlalchemy import LargeBinary
from sqlalchemy import create_engine, Table, Column, update, String, JSON, MetaData
from sqlalchemy import event
from ibm_watsonx_ai.foundation_models import ModelInference
from transformers import AutoProcessor
from google.cloud.alloydb.connector import Connector
from google.cloud.alloydbconnector.enums import IPTypes


# --- Hardcoded configuration for both local and cloud ---
USE_ALLOYDB_CONNECTOR = True  # Set to True to use AlloyDB connector (cloud), False for local


credentials = {
    "url": 'https://us-south.ml.cloud.ibm.com',
    "apikey": 'XDiRCehfnJA-BSC_URM_PgCT-TQoznaYhd5jJZ0PKHZi'
}
project_id = '4bf4e5d6-d94c-4b68-85af-c9d0206e0194'

text_llm = WatsonxLLM(
    model_id="ibm/granite-3-2-8b-instruct",
    url=credentials.get("url"),
    apikey=credentials.get("apikey"),
    project_id=project_id,
    params={
        GenParams.DECODING_METHOD: "greedy",
        GenParams.TEMPERATURE: 0,
        GenParams.MIN_NEW_TOKENS: 5,
        GenParams.MAX_NEW_TOKENS: 250
    },
)

image_llm = WatsonxLLM(
    model_id="ibm/granite-vision-3-2-2b",
    url=credentials.get("url"),
    apikey=credentials.get("apikey"),
    project_id=project_id,
    params={
        GenParams.DECODING_METHOD: "greedy",
        GenParams.TEMPERATURE: 0,
        GenParams.MIN_NEW_TOKENS: 5,
        GenParams.MAX_NEW_TOKENS: 250
    },
)

# image_llm = Replicate(
#     model="ibm/granite-vision-3-2-2b",
#     replicate_api_token=credentials.get("apikey")
# )

#vision_processor = AutoProcessor.from_pretrained("iibm-granite/granite-vision-3.2-2b")

embeddings = HuggingFaceEmbeddings(model_name="ibm-granite/granite-embedding-278m-multilingual")


# Local connection string (psycopg2)
CONNECTION_STRING = "postgresql+psycopg2://postgres:T8UQUIPiu#IZOZe3@34.174.7.160:5432/postgres?options=-csearch_path=boiling_point_vdb"

PSC_CONNECTION_STRING = "postgresql+psycopg2://postgres:T8UQUIPiu#IZOZe3@10.10.0.2:5432/postgres?options=-csearch_path=boiling_point_vdb"

# AlloyDB (cloud) settings
ALLOYDB_INSTANCE_URI = "projects/vaulted-hangout-460908-n9/locations/us-south1/clusters/boiling-point/instances/primary-instance"
DB_USER = "postgres"
DB_PASSWORD = "T8UQUIPiu#IZOZe3"
DB_NAME = "postgres"


# CONNECTION_STRING = "postgresql+psycopg2://postgres:T8UQUIPiu#IZOZe3@34.174.7.160:5432/postgres?options=-csearch_path=boiling_point_vdb"

COLLECTION_NAME = "boiling_point_vdb.final_data"


if USE_ALLOYDB_CONNECTOR:
    # Use the same creator pattern for PGVector
    connector = Connector()
    def getconn():
        return connector.connect(
            ALLOYDB_INSTANCE_URI,
            "pg8000",
            user=DB_USER,
            password=DB_PASSWORD,
            db=DB_NAME,
            ip_type=IPTypes.PUBLIC
        )
    
    engine = sqlalchemy.create_engine(
    "postgresql+pg8000://",             # empty URL → connector supplies sockets
    creator=getconn,
    pool_pre_ping=True, pool_size=10, max_overflow=2
   )
    
    # Set search_path for every new connection
    @event.listens_for(engine, "connect")
    def set_search_path(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute('SET search_path TO boiling_point_vdb;')
        cursor.close()
    
    vectorstore = PGVector(
        connection_string="postgresql+pg8000://",  # dummy, but required
        collection_name    = COLLECTION_NAME,
        connection         = engine,        # can also use connection_string="..."
        embedding_function = embeddings
    )

    # vectorstore = PGVector(
    #     collection_name=COLLECTION_NAME,
    #     connection_string=PSC_CONNECTION_STRING,
    #     embedding_function=embeddings,
    # )
else:
    vectorstore = PGVector(
        collection_name=COLLECTION_NAME,
        connection_string=CONNECTION_STRING,
        embedding_function=embeddings,
    )

    # Create SQLAlchemy engine and metadata
    engine = create_engine(CONNECTION_STRING)

retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

@tool
def get_context(input: str):
    """Retrieve relevant context from the vector store based on a question."""
    print(input)
    docs = retriever.get_relevant_documents(input)
    print(docs)
    response = "\n\n".join([doc.page_content for doc in docs])
    print("Retrieved context:")
    print(response)
    return response


tools = [get_context]

options_prompt_template = """
You are an expert advisor on climate action.

Use the following context to help answer the question:

{context}

Given the role: **{role}**  
And the location: **{location}**

Suggest the **three most impactful and realistic actions** that this person can take to help solve or mitigate climate problems in India. Each action should be:

1. Aligned with the person's capabilities and influence based on their role.
2. Locally relevant to the environmental and socio-economic context of the location.
3. Feasible, measurable, and contributing toward long-term sustainability.

Respond **ONLY** with JSON in the exact format below. Do **NOT** add explanations or markdown fences.

{{
  "Action 1": "First action description.",
  "Action 2": "Second action description.",
  "Action 3": "Third action description."
}}

(Include 3–5 clear actions. Be specific and practical.)

Do not include any additional text, explanation, or formatting outside the JSON object.

"""

follow_up_prompt_template = """
You are an expert sustainability advisor helping users take action on climate issues.

Context:
{context}

Selected Action:
{action}

Based on the above context and the selected action, provide a concise, step-by-step guide that the user can follow to implement this action effectively in India.

Respond **ONLY** with JSON in the exact format below. Do **NOT** add explanations or markdown fences.

{{
  "Step 1": "First step description.",
  "Step 2": "Second step description.",
  "Step 3": "Third step description."
}}

(Include 3–5 clear steps. Be specific and practical.)

Do not include any additional text, explanation, or formatting outside the JSON object.

"""

vision_steps_complete_template = """
You are a sustainability implementation evaluator. You are given:

1. The overall action the user is trying to implement.
2. Step-by-step descriptions of what the user attempted.
3. Photos showing the results of each step.
4. Additional context to inform your understanding of the images.

Context:
{{context}}

Action:
{{action}}

Your task is to carefully observe each photo corresponding to each step, and describe everything you can infer from it, especially regarding the environment, objects, people, tools, progress, or any indicators of sustainability practices.

{% for step, photo in steps_and_photos %}
Step: {{ loop.index }}
Description: {{ step }}
Photo: [see attached image]

{% endfor %}

Instructions:
- For each step, provide detailed visual observations.
- Do NOT evaluate, rate, or provide opinions — only describe what you see and can infer from the image.
- Include all visible elements relevant to the step.
- Your response must follow this exact format and include **no extra text**:

Respond **ONLY** with JSON in the exact format below. Do **NOT** add explanations or markdown fences.

{
"steps_and_observations":
{% for step, photo in steps_and_photos %}
"Step": {{ loop.index }}
"Description": {{ step }}
"Observation": "..."

{% endfor %}
}

Do not include any additional text, explanation, or formatting outside the JSON object.

"""


text_steps_completed_template = """
You are a sustainability implementation evaluator. You are given:

1. The overall action the user is trying to implement.
2. Step-by-step descriptions of what the user attempted.
3. Observations derived from Photos describing the results of each step.
4. Additional context to evaluate correctness and effectiveness.

Context:
{{context}}

Action:
{{action}}

Evaluate the following steps based on their corresponding photos:

{% for step, description, observation in steps_and_observations %}
Step: {{ step }}
Description: {{ description }}
Observation: {{ observation }}

{% endfor %}

Instructions:
- Based on all steps, rate the action from 1 (poor) to 5 (excellent) based on the each step and corresponding Observation.
- Provide 1-2 lines of feedback explaining your rating.
- Be specific and reference context if needed.

Respond **ONLY** with JSON in the exact format below. Do **NOT** add explanations or markdown fences.

{
    "Action":{{action}}, ""Rating": "X/5", "Feedback": "..."
}

Do not include any additional text, explanation, or formatting outside the JSON object.

"""


options_prompt_template = PromptTemplate(
    input_variables=["context", "role", "location"],  # placeholders used in the template string
    template=options_prompt_template
)

follow_up_prompt_template = PromptTemplate(
    input_variables=["context", "action"],  # placeholders used in the template string
    template=follow_up_prompt_template
)

text_jinja_template = Template(text_steps_completed_template)

vision_jinja_template = Template(vision_steps_complete_template)

# steps_completed_template = PromptTemplate(
#     input_variables=["context", "action", "steps_and_photos"],  # placeholders used in the template string
#     template=steps_completed_template
# )

def render_text_steps_prompt(inputs):
    rendered = text_jinja_template.render(
        context=inputs["context"],
        action=inputs["action"],
        steps_and_photos=inputs["steps_and_photos"]
    )
    return rendered

def render_vision_steps_prompt(inputs):
    rendered = vision_jinja_template.render(
        context=inputs["context"],
        action=inputs["action"],
        steps_and_photos=inputs["steps_and_photos"]
    )
    return rendered

def parse_json_output(text):
    try:
        print("Raw LLM Output:", text)

        # Remove unwanted ''' and json string
        if text.startswith("'''json"):
            text = text.strip("'''json").strip("'''").strip()
        elif text.startswith("```json"):
            text = text.strip("```json").strip("```").strip()

        #print(text)
        parsed = json.loads(text)
        #print('parsing...')
        #print(parsed)
        return AgentFinish({"output": parsed}, text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON: {e}\nOriginal text: {text}")

def contextual_options_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(f"""Role: {x["role"]}, Location: {x["location"]}"""),
        "role": lambda x: x["role"],
        "location": lambda x: x["location"]
    }) | options_prompt_template | text_llm | RunnableLambda(parse_json_output)

def contextual_follow_up_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(x["input"]),
        "action": lambda x: x["action"]
    }) | follow_up_prompt_template | text_llm | RunnableLambda(parse_json_output)

# def invoke_vision_llm():
#     return RunnableLambda(lambda x: image_llm.invoke({
#         "input": render_vision_steps_prompt({
#             "context": x["context"],
#             "action": x["action"],
#             "steps_and_photos": [(step, "[see attached image]") for step, _ in x["steps_and_photos"]]
#         }),
#         "input_media": [
#             {"type": "image", "data": photo}  # assume already base64
#             for _, photo in x["steps_and_photos"]
#         ]
#     }))

def call_watsonx_vision_model(prompt: str, base64_images: list[str]):
    # model = ModelInference(
    #     model_id="ibm/granite-vision-3-2-2b",
    #     url=credentials.get("url"),
    #     apikey=credentials.get("apikey"),
    #     project_id=project_id
    # )

    # model_inference = ModelInference(
    #         model_id="ibm/granite-vision-3-2-2b",
    #         params={
    #             GenParams.MAX_NEW_TOKENS: 25
    #         },
    #         credentials={
    #             "apikey": credentials.get("apikey"),
    #             "url": credentials.get("url")
    #         },
    #         project_id=project_id
    #         )
    
    # inputs = {
    #     "input": prompt,
    #     "input_media": [{"type": "image", "data": img} for img in base64_images],
    #     "decoding_method": "greedy",
    #     "temperature": 0,
    #     "min_new_tokens": 5,
    #     "max_new_tokens": 250
    # }

    vision = ModelInference(
        model_id       = "ibm/granite-vision-3-2-2b",
        credentials    = {"apikey": credentials.get("apikey"), "url": credentials.get("url")},
        project_id     = project_id,
        params         = {
            GenParams.DECODING_METHOD: "greedy",
            GenParams.TEMPERATURE: 0,
            GenParams.MIN_NEW_TOKENS: 5,
            GenParams.MAX_NEW_TOKENS: 250,
        },
    )

    # return model_inference.generate_text(params=inputs)

    # return image_llm.invoke(prompt,image=base64_images)
    # return image_llm.invoke(input)

    response = vision.generate_text(
        prompt = prompt,
        params = {
            # **the model expects these two keys exactly**
            "input": prompt,
            "input_media": [
                {"type": "image", "data": img} for img in base64_images
            ],
        },
    )

    # watsonx returns a list of generations; grab the first
    return response["results"][0]["generated_text"]

def prepare_image_payload():
    return RunnableLambda(lambda x: call_watsonx_vision_model(
        render_vision_steps_prompt({
            "context": x["context"],
            "action": x["action"],
            "steps_and_photos": [(step, "[see attached image]") for step, _ in x["steps_and_photos"]]
        }),
        [photo for _, photo in x["steps_and_photos"]]
    ))

text_chain = RunnableLambda(render_text_steps_prompt) | text_llm | RunnableLambda(parse_json_output)

def contextual_steps_completed_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(x["input"]),
        "action": lambda x: x["action"],
        "steps_and_photos": lambda x: [(step["step_description"], step["step_photos"]) for step in x["steps"]]
    }) | prepare_image_payload() | text_chain

options_agent = contextual_options_chain()

options_agent_executor = AgentExecutor(
    agent=options_agent,
    tools=tools,  # can be empty if not calling tools dynamically
    verbose=True,
    handle_parsing_errors=True
)

follow_up_agent = contextual_follow_up_chain()

follow_up_agent_executor = AgentExecutor(
    agent=follow_up_agent,
    tools=tools,  # can be empty if not calling tools dynamically
    verbose=True
)

steps_completed_agent = contextual_steps_completed_chain()

steps_completed_agent_executor = AgentExecutor(
    agent=steps_completed_agent,
    tools=tools,  # can be empty if not calling tools dynamically
    verbose=True
)


metadata = MetaData()

# Define the steps table
steps_table = Table(
    "user_steps",
    metadata,
    Column("email_id", String, nullable=False),
    Column("action_name", String, nullable=False),
    Column("step_description", String, nullable=False),
    Column("status", String, default="pending"),  # Status of the step (e.g., pending, completed)
    Column("photos", LargeBinary, nullable=True), # List of photo URLs from s3 or ibm storage.
    Column("metadata", JSON, nullable=True),  # Optional metadata for the step
)

#Define the action table
actions_table = Table(
    "user_actions",
    metadata,
    Column("email_id", String, nullable=False),
    Column("action_name", String, nullable=False),
    Column("rating", String, nullable=True), # Rating of the step.
    Column("rating_reason", String, nullable=True), # Rating reason of the step.
    Column("metadata", JSON, nullable=True),  # Optional metadata for the action
)

# Create the table in the database
metadata.create_all(engine)

# Initialize FastAPI app
app = FastAPI()

# Models
class UserRequest(BaseModel):
    role: str
    location: str

class OptionSelection(BaseModel):
    email_id: str
    action: str

class StepCompletion(BaseModel):
    email_id: str
    action: str
    step_description: str

# API 1: Retrieve relevant documents and get options from WatsonX
@app.post("/get-options")
async def get_options(request: UserRequest):
    try:
        #do a vector search based on role, location and add language
        response = options_agent_executor.invoke({
            "role": request.role,
            "location": request.location
        })

        print(response)
        return response  
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving options: {str(e)}")
    
# API 2: Generate steps, persist in DB, and track updates
@app.post("/select-option")
async def select_option(selection: OptionSelection):
    try:
        # Generate steps using LLM
        #steps = llm.generate(f"Generate steps for the selected option: {selection.selected_option}")

        response = follow_up_agent_executor.invoke({
            "input": "ground water",
            "action": selection.action
        })

        #do a vector search based on role, location and add language

        # Extract the "output" key from the response
        steps = response.get("output", {})  # Get the dictionary of steps

        with engine.connect() as connection:
            transaction = connection.begin()  # Start a transaction
            for step_name, step_description in steps.items():
                connection.execute(
                    steps_table.insert().values(
                        email_id=selection.email_id,
                        action_name=selection.action,
                        step_description=step_description,
                        status="pending"
                    )
                )
            transaction.commit() 
            result = connection.execute(
                steps_table.select()
                .where(
                    steps_table.c.email_id == selection.email_id,
                    steps_table.c.action_name == selection.action
                )
            )
            steps_result = result.fetchall()

            print(steps_result)

        return {"message": "Steps generated and persisted successfully", "steps": steps}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating steps: {str(e)}")

# API 3: Submit photos and get rating from LLM
@app.post("/submit-steps")
async def submit_steps(completion: str = Form(...),step_photos: List[UploadFile] = File(...) ):
    try:

        # Parse the stringified JSON into a Python list
        completion = json.loads(completion)

        print(completion)

        # Ensure the number of step_data matches the number of photos
        if len(completion) != len(step_photos):
            raise HTTPException(status_code=400, detail="Please upload photo for each step selected.")

        with engine.connect() as connection:
            transaction = connection.begin()

            # Iterate over each step data and photo
            for step, step_photo in zip(completion, step_photos):
                print(step)
                photo_data = await step_photo.read()
                #photo_data = base64.b64encode(photo_data).decode("utf-8")
                print(photo_data)
                connection.execute(
                    update(steps_table)
                    .where(
                        steps_table.c.email_id == step.get('email_id'),
                        steps_table.c.action_name == step.get('action'),
                        steps_table.c.step_description == step.get('step_description')
                    )
                    .values(status='completed', photos=photo_data)
                )

            transaction.commit()  #

        steps = []
        # Check if all steps for the given email_id and action_name are completed
        email_id = completion[0].get('email_id')
        action_name = completion[0].get('action')
        with engine.connect() as connection:
            transaction = connection.begin() 
            result = connection.execute(
                steps_table.select()
                .where(
                    steps_table.c.email_id == email_id,
                    steps_table.c.action_name == action_name
                )
            )
            steps = result.mappings().all()
            transaction.commit()  #
        print(steps)

        # Verify if all steps are completed
        all_completed = all(step["status"] == "completed" for step in steps)

        if all_completed:

            response = steps_completed_agent_executor.invoke({
                "input": "ground water",
                "action": action_name,
                "steps": [
                    {
                        "step_description": step["step_description"],
                        "step_photos": base64.b64encode(step["photos"]).decode("utf-8")
                    } for step in steps
                ]
                })

            print('here')
            print(response.get("output",{}))
            # Convert response into a list of dictionaries
            
            parsed_data = {"rating": response.get("output",{}).get("Rating",{}), "reason": response.get("output",{}).get("Feedback",{})}

            print(parsed_data)

            # Update the rating column in the database
            with engine.connect() as connection:
                connection.execute(
                    update(actions_table)
                    .where(
                        steps_table.c.email_id == email_id,
                        steps_table.c.action_name == action_name
                    )
                    .values(
                        rating=parsed_data["rating"],
                        rating_reason=parsed_data["reason"]
                    )
                )

            return {"message": "All Steps completed and rated successfully", "ratings": parsed_data}

        return {"message": "Successfully submitted step status"}

    except Exception as e:
        raise e
        raise HTTPException(status_code=500, detail=f"Error submitting steps: {str(e)}")
    
@app.get("/health")
def test_vector():
    try:
        # Step 1: Check vector dimension
        query_vector = embeddings.embed_query("test")
        print(f"Vector dimension: {len(query_vector)}") 

        # Step 2: Add test documents if needed
        vectorstore.add_texts(["soil contains nitrogen", "nitrogen is important", "plants absorb nitrogen"])

        # Perform a simple query to test the vector store connection
        docs = vectorstore.similarity_search("""soil contains units of nitrogen""",k=3)
        if docs:
            return {"status": "ok", "message": "Vector store is healthy."}
        else:
            return {"status": "error", "message": "No documents found in vector store."}
    except Exception as e:
        return {"status": "error", "message": str(e)}
