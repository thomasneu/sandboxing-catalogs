gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:terraform-automation-sp@PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin" \
  --condition=None

# 2. Compute Admin - for any compute resources
gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:terraform-automation-sp@PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin" \
  --condition=None

# 3. Storage Admin - for GCS buckets
gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:terraform-automation-sp@PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin" \
  --condition=None

# 4. Service Account Admin - to create/manage service accounts
gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:terraform-automation-sp@PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin" \
  --condition=None

# 5. Service Account Key Admin - to create SA keys
gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:terraform-automation-sp@PROJECT-ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountKeyAdmin" \
  --condition=None