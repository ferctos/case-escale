up:
	# Deploy the ELT environment through Terraform
	terraform init && terraform apply -auto-approve

down:
	# Destroy the ELT environment through Terraform 
	terraform apply -destroy -auto-approve

get_bigquery_creds:
	# Get Service Account credentials for BigQuery and export this to BIGQUERY_CRED environment variable 
	terraform output airbyte_sa_key | xargs echo {} | python -m base64 -d

access_airbyte:
	gcloud beta compute ssh --zone "southamerica-east1-a" "escale-data-airbyte"  --project "escale-data" -- -L 8000:localhost:8000 -L 8001:localhost:8001 -N -f

access_metabase:
	gcloud beta compute ssh --zone "southamerica-east1-a" "escale-data-metabase"  --project "escale-data" -- -L 3000:localhost:3000 -N -f
	
