from langchain_ibm import WatsonxLLM
from langchain_community.llms import Replicate
from langchain_community.vectorstores.pgvector import PGVector
from langchain.prompts import PromptTemplate
from ibm_watson_machine_learning.metanames import GenTextParamsMetaNames as GenParams
from langchain_core.agents import AgentFinish
from langchain.schema.runnable import RunnableLambda
from langchain.agents import AgentExecutor
from langchain.tools import tool
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.prompts import PromptTemplate
from langchain_core.runnables import RunnableMap
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, HTTPException
from fastapi import UploadFile, File, Form
from typing import List,Optional
from pydantic import BaseModel
from jinja2 import Template
import json
import base64
import io
from PIL import Image, ImageOps
from fastapi import File, UploadFile
import sqlalchemy
from sqlalchemy import LargeBinary
from sqlalchemy import create_engine, Table, Column, update, String, JSON, MetaData
from sqlalchemy import event
from ibm_watsonx_ai.foundation_models import ModelInference
from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from google.cloud.alloydb.connector import Connector
from google.cloud.alloydbconnector.enums import IPTypes


# --- Hardcoded configuration for both local and cloud ---
USE_ALLOYDB_CONNECTOR = False  # Set to True to use AlloyDB connector (cloud), False for local

# Password hashing utility
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Dependency to get the database session
def get_db():
    with engine.connect() as connection:
        yield connection
from transformers import AutoProcessor
from fastapi.middleware.cors import CORSMiddleware

credentials = {
    "url": 'https://us-south.ml.cloud.ibm.com',
    "apikey": 'GUqW4lwE8DZGPl-DvXavZY6cvVt7no6Ni34YUm2etseJ'
}

project_id = '4bf4e5d6-d94c-4b68-85af-c9d0206e0194'

text_llm = WatsonxLLM(
    model_id="ibm/granite-3-2-8b-instruct",
    url=credentials.get("url"),
    apikey=credentials.get("apikey"),
    project_id=project_id,
    params={
        GenParams.DECODING_METHOD: "sample",
        GenParams.TEMPERATURE: 0.5,
        GenParams.MIN_NEW_TOKENS: 1,
        GenParams.MAX_NEW_TOKENS: 4096,
        "repetition_penalty": 1,
        "stop_sequences": []   
    },
)

vision = ModelInference(
        model_id = "ibm/granite-vision-3-2-2b",
        credentials={
                "apikey": credentials.get("apikey"),
                "url": credentials.get("url")
        },
        project_id = project_id,
        params = {
            "max_tokens": 4096,
            "temperature": 0
        }
    )

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

    docs = retriever.get_relevant_documents(input)
    response = "\n\n".join([doc.page_content for doc in docs])
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

    Respond **ONLY** in exact JSON format below. **The JSON keys must remain in English as shown. Only translate the values into {language}.** Do **NOT** add explanations or markdown fences.

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

    Respond **ONLY** in exact JSON format below. **The JSON keys must remain in English as shown. Only translate the values into {language}.** Do **NOT** add explanations or markdown fences.

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
    2. Description of what the user attempted.
    3. Photo showing the results.
    4. Additional context to inform your understanding of the images.

    Context:
    {{context}}

    Action:
    {{action}}

    Description:
    {{description}}

    Your task is to carefully observe photo , and describe everything you can infer from it in as per the provided context, action and description.


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

Evaluate the following steps based on their corresponding description and observation:

{% for description, observation in steps_and_observations %}
Step: {{ loop.index }}
Description: {{ description }}
Observation: {{ observation }}

{% endfor %}

Instructions:
- Based on all steps, rate the action from 1 (poor) to 5 (excellent).
- Provide 1-2 lines of feedback explaining your rating.
- Be specific and reference context if needed.

Respond **ONLY** with JSON in the exact format below. **The JSON keys must remain in English as shown. Only translate the values into {{language}}. Do **NOT** add explanations or markdown fences.

{
    "Action":"{{action}}", "Rating": "X/5", "Feedback": "..."
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

def render_text_steps_prompt(inputs):
    rendered = text_jinja_template.render(
        context=inputs["context"],
        action=inputs["action"],
        steps_and_observations=inputs["steps_and_observations"],  # List of tuples (description, observation)
        language=inputs["language"]
    )
    return rendered

def render_vision_steps_prompt(inputs):
    rendered = vision_jinja_template.render(
        context=inputs["context"],
        action=inputs["action"],
        description=inputs["description"]
    )
    return rendered

def parse_json_output(text):
    try:
        # Remove unwanted ''' and json string
        if text.startswith("'''json"):
            text = text.strip("'''json").strip("'''").strip()
        elif text.startswith("```json"):
            text = text.strip("```json").strip("```").strip()
        parsed = json.loads(text)
        return AgentFinish({"output": parsed}, text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON: {e}\nOriginal text: {text}")

def contextual_options_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(f"""Role: {x["role"]}, Location: {x["location"]}"""),
        "role": lambda x: x["role"],
        "location": lambda x: x["location"],
        "language": lambda x: x["language"],
    }) | options_prompt_template | text_llm | RunnableLambda(parse_json_output)

def contextual_follow_up_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(f"""Role: {x["role"]}, Location: {x["location"]}"""),
        "action": lambda x: x["action"],
        "language": lambda x: x["language"],
    }) | follow_up_prompt_template | text_llm | RunnableLambda(parse_json_output)

def encode_image(image_bytes: bytes, format: str = "PNG") -> str:
    """
    Converts raw image bytes to RGB and returns a base64-encoded string (no data URI prefix),
    ready for input into Watsonx Vision model.

    Args:
        image_bytes: Raw image bytes (e.g., from Postgres BYTEA).
        format: Format to encode in ('PNG' recommended).

    Returns:
        base64-encoded image string (no prefix).
    """
    # Load image from bytes
    image = Image.open(io.BytesIO(image_bytes))

    # Handle orientation from EXIF if needed
    image = ImageOps.exif_transpose(image)

    # Convert to RGB (some formats like PNG might include alpha)
    image = image.convert("RGB")

    # Encode to base64
    buffer = io.BytesIO()
    image.save(buffer, format=format)
    base64_encoded = base64.b64encode(buffer.getvalue()).decode("utf-8")

    return base64_encoded

def call_watsonx_vision(prompt: str, steps_and_phots:list, action: str, context: str, language: str):

    final_response = {"action": action, "context": context, "steps_and_observations": [], "language": language}

    for step_desc, step_image in steps_and_phots:
        message = [
            {
                "role": "user",
                "content": [{
                    "type": "text",
                    "text": prompt.format(description=step_desc)
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{step_image}",
                    }
                }]
            }
        ]
        response = vision.chat(messages=message)

        final_response['steps_and_observations'].append((step_desc,response['choices'][0]['message']['content']))

    return final_response

def fetch_image_description():
    return RunnableLambda(lambda x: call_watsonx_vision(
        render_vision_steps_prompt({
            "context": x["context"],
            "action": x["action"],
            "description": "{{{{description}}}}"
        }),
        x["steps_and_photos"],
        x["action"],
        x["context"],
        x["language"]
    ))

text_chain = RunnableLambda(render_text_steps_prompt) | text_llm | RunnableLambda(parse_json_output)

def contextual_steps_completed_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(f"""Role: {x["role"]}, Location: {x["location"]}"""),
        "action": lambda x: x["action"],
        "steps_and_photos": lambda x: [(step["step_description"], step["step_photos"]) for step in x["steps"]],
        "language": lambda x: x["language"]
    }) | fetch_image_description() | text_chain

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

# Define the users table
users_table = Table(
    "users",
    metadata,
    Column("email_id", String, primary_key=True, nullable=False),
    Column("name", String, nullable=False),
    Column("password", String, nullable=False),  # Hashed password
    Column("role", String, nullable=False),  # User's role (e.g., admin, user)
    Column("location", String, nullable=False),  # User's location
    Column("language", String, nullable=False),  # User's preferred language
)

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
    Column("status", String, default="pending"),  # Status of the action (e.g., pending, completed)
    Column("metadata", JSON, nullable=True),  # Optional metadata for the action
)

# Create the table in the database
metadata.create_all(engine)

# Initialize FastAPI app

app = FastAPI()

# Enable all cross-origin requests (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Models
class UserRequest(BaseModel):
    role: str
    location: str
    language: str

class ActionSelection(BaseModel):
    role: str
    location: str
    email_id: str
    action: str
    status: Optional[str] = None
    language: str

class StepCompletion(BaseModel):
    email_id: str
    action: str
    step_description: str
    language: str

# API 1: Retrieve relevant documents and get actions from WatsonX
@app.post("/get-actions")
async def get_actions(request: UserRequest):
    try:
        #do a vector search based on role, location and add language
        response = options_agent_executor.invoke({
            "role": request.role,
            "location": request.location,
            "language": request.language
        })

        return response  
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving options: {str(e)}")
    
# API 2: Generate steps, persist in DB, and track updates
@app.post("/select-action")
async def select_action(selection: ActionSelection):
    try:

        response = follow_up_agent_executor.invoke({
            "role": selection.role,
            "location": selection.location,
            "action": selection.action,
            "language": selection.language
        })

        # Extract the "output" key from the response
        steps = response.get("output", {})  # Get the dictionary of steps

        with engine.connect() as connection:
            transaction = connection.begin()  # Start a transaction
            connection.execute(
                    actions_table.insert()
                    .values(
                        email_id=selection.email_id,
                        action_name=selection.action
                    )
            )
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
            steps_result = result.mappings().all()

        return {"message": "Steps generated and persisted successfully", "steps": steps}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating steps: {str(e)}")

# API 3: Submit photos and get rating from LLM
@app.post("/submit-steps")
async def submit_steps(completion: str = Form(...),step_photos: List[UploadFile] = File(...) ):
    try:

        # Parse the stringified JSON into a Python list
        completion = json.loads(completion)

        # Ensure the number of step_data matches the number of photos
        if len(completion) != len(step_photos):
            raise HTTPException(status_code=400, detail="Please upload photo for each step selected.")

        with engine.connect() as connection:
            transaction = connection.begin()

            # Iterate over each step data and photo
            for step, step_photo in zip(completion, step_photos):
                photo_data = await step_photo.read()
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
        location = completion[0].get('location')
        role = completion[0].get('role')
        language = completion[0].get('language')
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

        # Verify if all steps are completed
        all_completed = all(step["status"] == "completed" for step in steps)

        if all_completed:
        
            response = steps_completed_agent_executor.invoke({
                "role": role,
                "location": location,
                "action": action_name,
                "language": language,
                "steps": [
                    {
                        "step_description": step["step_description"],
                        "step_photos": encode_image(step["photos"]) if step["photos"] else ""
                    } for step in steps
                ]
                })

            # Convert response into a list of dictionaries
            
            parsed_data = {"rating": response.get("output",{}).get("Rating",{}), "reason": response.get("output",{}).get("Feedback",{})}

            # Update the rating column in the database
            with engine.connect() as connection:
                transaction = connection.begin() 
                connection.execute(
                    update(actions_table)
                    .where(
                        actions_table.c.email_id == email_id,
                        actions_table.c.action_name == action_name
                    )
                    .values(
                        rating=parsed_data["rating"],
                        rating_reason=parsed_data["reason"]
                    )
                )
                transaction.commit()

            return {"message": "All Steps completed and rated successfully", "ratings": parsed_data}

        return {"message": "Successfully submitted step status"}

    except Exception as e:
        raise e
        raise HTTPException(status_code=500, detail=f"Error submitting steps: {str(e)}")
    
@app.post("/login")
async def login(email_id: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    try:
        # Query the user from the database
        query = users_table.select().where(users_table.c.email_id == email_id)
        user_result = db.execute(query).mappings().fetchone()

        if not user_result:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Validate the password
        stored_password = user_result["password"]
        if not pwd_context.verify(password, stored_password):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Fetch user actions
        actions_query = actions_table.select().where(actions_table.c.email_id == email_id)
        actions_result = db.execute(actions_query).mappings().fetchall()

        # Format the response
        user_details = {
            "email_id": user_result["email_id"],
            "name": user_result["name"],
            "role": user_result["role"],
            "actions": [
                {
                    "action_name": action["action_name"],
                    "status": action["status"]
                }
                for action in actions_result
            ],
            "location": user_result["location"],
            "language": user_result["language"]
        }

        return {"message": "Login successful", "user": user_details}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error during login: {str(e)}")
    

@app.post("/signup")
async def signup(
    email_id: str = Form(...),
    password: str = Form(...),
    name: str = Form(...),
    role: str = Form(...),
    location: str = Form(...),
    language: str = Form(...),
    db: Session = Depends(get_db)
):
    try:
        # Hash the password
        hashed_password = pwd_context.hash(password)

        with db.begin():
            # Insert the user into the database
            query = users_table.insert().values(
                email_id=email_id,
                password=hashed_password,
                name=name,
                role=role,
                location=location,
                language=language
            )
            db.execute(query)

        return {"message": "User registered successfully"}

    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email ID already exists"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error during signup: {str(e)}"
        )
