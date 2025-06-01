# boiling_point_server

A new FastAPI project.

## Getting Started

pip3 install langchain langchain-ibm langchain_community ibm-watsonx-ai ibm_watson_machine_learning pgvector psycopg2-binary fastapi uvicorn sentence-transformers

source venv/bin/activate

python3 boiling_point.py

### How to expose the api's publically using the ngrok. Please follow the deatailed below steps to expose the api's using ngrok

Steps:
1.  Install ngrok:
Download from https://ngrok.com/download
Or via command line:
       brew install ngrok    # macOS
       sudo apt install ngrok # Ubuntu
       choco install ngrok   # Windows
2.  Sign up at ngrok.com and get your auth token (only needed once):
       ngrok config add-authtoken YOUR_AUTH_TOKEN
3.  Start your FastAPI app locally
    uvicorn boiling_point:app --host 0.0.0.0 --port 8000
4.  Expose your local port with ngrok
     ngrok http 8000
5.  You'll get a public HTTPS URL
     https://a1b2c3d4.ngrok.io
6.  You can now access your API at:
    https://a1b2c3d4.ngrok.io/docs


### How to deploy our fastapi's using the google cloud. Please follow below detailed Steps 

1. Install the google-cloud-sdk:
    brew install --cask google-cloud-sdk -->#macos
    choco install googlecloudsdk  --> #windows
2. Initialize the google-cloud using below command
    gcloud init
3. When you run the above it requets for configurations like your google account and the project deatils select our shared project(projectid: vaulted-hangout-460908-n9)
4. Create the respective Dockerfile for build and deploy the code in gooogle cloud plaesae use the Dockerfile that is already under the boiling_point_server.
5. Checkout to the location where we have the fastpi code . In our case go the location where boiling_point.py and run the below Command
5. Use below command to run and deploy in google cloud
    gcloud run deploy --source .
6. When you run the above command please provide the service name that you want to expose and the region where you want to deploy the service.
7. After doing the above steps it will build and deploy in google cloud and after successful execution of the command you will get the service url where the api's has been exposed.

