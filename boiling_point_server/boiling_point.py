from langchain_ibm import WatsonxLLM
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
from pydantic import BaseModel
import re
import json
from sqlalchemy import create_engine, Table, Column, update, String, JSON, MetaData
from fastapi.middleware.cors import CORSMiddleware

credentials = {
    "url": 'https://us-south.ml.cloud.ibm.com',
    "apikey": 'XDiRCehfnJA-BSC_URM_PgCT-TQoznaYhd5jJZ0PKHZi'
}
project_id = '4bf4e5d6-d94c-4b68-85af-c9d0206e0194'

llm = WatsonxLLM(
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

embeddings = HuggingFaceEmbeddings(model_name="ibm-granite/granite-embedding-30m-english")

CONNECTION_STRING = "postgresql+psycopg2://postgres:T8UQUIPiu#IZOZe3@34.174.7.160:5432/postgres?options=-csearch_path=boiling_point_vdb"

COLLECTION_NAME = "boiling_point_vdb.items"

vectorstore = PGVector(
    collection_name=COLLECTION_NAME,
    connection_string=CONNECTION_STRING,
    embedding_function=embeddings,
)

retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

@tool
def get_context(question: str):
    """Retrieve relevant context from the vector store based on a question."""
    docs = retriever.get_relevant_documents(question)
    print(docs)
    response = "\n\n".join([doc.page_content for doc in docs])
    print("Retrieved context:")
    print(response)
    return response


tools = [get_context]

retry_prompt = PromptTemplate(
    input_variables=["output", "original_prompt"],
    template=(
        "The previous output was invalid JSON:\n{output}\n"
        "Please fix the JSON output to conform to the required format "
        "based on this original prompt:\n{original_prompt}"
    )
)

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

steps_completed_template = """
You are a sustainability implementation evaluator. You are given:

1. The overall action the user is trying to implement.
2. Step-by-step descriptions of what the user attempted.
3. Photos showing the results of each step.
4. Additional context to evaluate correctness and effectiveness.

Context:
{context}

Action:
{action}

Evaluate the following steps based on their corresponding photos:

{% for step, photo in steps_and_photos %}
Step: {{ loop.index }}
Description: {{ step }}
Photo: {{ photo }}

{% endfor %}

Instructions:
- For each step, rate the implementation from 1 (poor) to 5 (excellent) based on the image.
- Provide 1-2 lines of feedback explaining your rating.
- Be specific and reference context if needed.

Respond **ONLY** with JSON in the exact format below. Do **NOT** add explanations or markdown fences.

{{
  "Step 1": {{"Rating: X/5" ,"Feedback: ..."}},
  "Step 2": {{"Rating: X/5" ,"Feedback: ..."}},
  "Step 3": {{"Rating: X/5" ,"Feedback: ..."}}
}}

(Continue for each step)

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

steps_completed_template = PromptTemplate(
    input_variables=["context", "action", "steps_and_photos"],  # placeholders used in the template string
    template=steps_completed_template
)

json_parser = JSONAgentOutputParser()

retry_chain = LLMChain(llm=llm, prompt=retry_prompt)

fixing_parser = OutputFixingParser(parser=json_parser, retry_chain=retry_chain)

def parse_json_output(text):
    try:
        parsed = json.loads(text)
        return AgentFinish({"output": parsed}, text)
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON: {e}\nOriginal text: {text}")

def contextual_options_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(x["input"]),
        "role": lambda x: x["role"],
        "location": lambda x: x["location"]
    }) | options_prompt_template | llm | RunnableLambda(parse_json_output)

def contextual_follow_up_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(x["input"]),
        "action": lambda x: x["action"]
    }) | follow_up_prompt_template | llm | RunnableLambda(parse_json_output)

def contextual_steps_completed_chain():
    return RunnableMap({
        "context": lambda x: get_context.invoke(x["input"]),
        "action": lambda x: x["action"],
        "steps_and_photos": lambda x: [
            (step["step_description"], step["step_photos"]) for step in x["steps"]
        ]
    }) | steps_completed_template | llm | RunnableLambda(parse_json_output)

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

# Create SQLAlchemy engine and metadata
engine = create_engine(CONNECTION_STRING)
metadata = MetaData()

# Define the steps table
steps_table = Table(
    "user_steps",
    metadata,
    Column("email_id", String, nullable=False),
    Column("action_name", String, nullable=False),
    Column("step_description", String, nullable=False),
    Column("status", String, default="pending"),  # Status of the step (e.g., pending, completed)
    Column("photos", String, nullable=True), # List of photo URLs from s3 or ibm storage.
    Column("rating", String, nullable=True), # Rating of the step.
    Column("rating_reason", String, nullable=True), # Rating reason of the step.
    Column("metadata", JSON, nullable=True),  # Optional metadata for the step
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

class OptionSelection(BaseModel):
    email_id: str
    action: str

class StepCompletion(BaseModel):
    email_id: str
    action: str
    step_description: str
    step_photos: str  # List of photo URLs or base64-encoded images

# API 1: Retrieve relevant documents and get options from WatsonX
@app.post("/get-options")
async def get_options(request: UserRequest):
    try:
        response = options_agent_executor.invoke({
            "input": "climate issues in India",
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
            "input": "climate issues in India",
            "action": selection.action
        })

        # Extract the "output" key from the response
        steps = response.get("output", {})  # Get the dictionary of steps

        with engine.connect() as connection:
            for step_name, step_description in steps.items():
                connection.execute(
                    steps_table.insert().values(
                        email_id=selection.email_id,
                        action_name=selection.action,
                        step_description=step_description,
                        status="pending"
                    )
                )

        return {"message": "Steps generated and persisted successfully", "steps": steps}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating steps: {str(e)}")

# API 3: Submit photos and get rating from LLM
@app.post("/submit-steps")
async def submit_steps(completion: list[StepCompletion]):
    try:
        for step in completion:
            step_description = step.step_description
            with engine.connect() as connection:
                connection.execute(
                    update(steps_table)
                    .where(
                        steps_table.c.email_id == step.email_id,
                        steps_table.c.action_name == step.action,
                        steps_table.c.step_description == step_description
                    )
                    .values(status='completed', photos=step.step_photos)
                )

        steps = []
        # Check if all steps for the given email_id and action_name are completed
        email_id = completion[0].email_id
        action_name = completion[0].action
        with engine.connect() as connection:
            result = connection.execute(
                steps_table.select()
                .where(
                    steps_table.c.email_id == email_id,
                    steps_table.c.action_name == action_name
                )
            )
            steps = result.fetchall()

        print(steps)

        # Verify if all steps are completed
        all_completed = all(step["status"] == "completed" for step in steps)

        if all_completed:

            response = steps_completed_agent_executor.invoke({
                "input": "climate issues in India",
                "action": action_name,
                "steps": [
                    {
                        "step_description": step["step_description"],
                        "step_photos": step["photos"] or []
                    } for step in steps
                ]
                })


            # Convert response into a list of dictionaries
            parsed_data = [{"rating": int(res["Rating"]), "reason": res["Feedback"]} for res in response]


            # Update the rating column in the database
            with engine.connect() as connection:
                for step, parsed in zip(steps, parsed_data):
                    connection.execute(
                        update(steps_table)
                        .where(
                            steps_table.c.email_id == email_id,
                            steps_table.c.action_name == action_name,
                            steps_table.c.step_description == step["step_description"]
                        )
                        .values(
                            rating=parsed["rating"],
                            rating_reason=parsed["reason"]
                        )
                    )

            return {"message": "All Steps completed and rated successfully", "ratings": parsed_data}

        return {"message": "Successfully submitted step status"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error submitting steps: {str(e)}")
