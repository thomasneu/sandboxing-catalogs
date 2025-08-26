# Service Principal Setup - Quick Guide

Step-by-step guide to create a Databricks service principal for Terraform automation.

## 🔧 Create Service Principal

### 1. Access Account Console
1. Go to `https://accounts.gcp.databricks.com`
2. Sign in with your account admin credentials
3. Navigate to **Settings** → **Identity and access** → **Service principals**

### 2. Create Service Principal
1. Click **Add service principal**
2. Enter name: `terraform-automation-sp`
3. Click **Add**
4. **Copy the Application ID** - this is your `client_id`

### 3. Generate Secret
1. Click on your service principal
2. Go to **OAuth secrets** tab
3. Click **Generate secret**
4. **Copy the secret immediately** - this is your `client_secret`
5. ⚠️ The secret won't be shown again!

### 4. Grant Permissions
1. Go to **Settings** → **Identity and access** → **Groups**
2. Click **Account admins**
3. Click **Add members** 
4. Add your service principal
5. Click **Save**

## 🔐 Using Credentials Securely

### Environment Variables (Recommended)
```bash
export TF_VAR_databricks_client_id="your-client-id"
export TF_VAR_databricks_client_secret="your-client-secret"

# Now run terraform without storing secrets in files
terraform apply
```

### Alternative: .env File
Create `.env` file (never commit to Git!):
```bash
export TF_VAR_databricks_client_id="your-client-id" 
export TF_VAR_databricks_client_secret="your-client-secret"
export TF_VAR_gcp_project_id="your-gcp-project"
```

Load and run:
```bash
source .env
terraform apply
```

## 🛡️ Security Best Practices

- ✅ **Never commit secrets** to version control
- ✅ **Use environment variables** instead of .tfvars files
- ✅ **Rotate secrets** every 90 days
- ✅ **Use minimal permissions** (Account admin required for workspace creation)
- ✅ **Monitor usage** in Databricks audit logs

## 🔍 Troubleshooting

**"Invalid client credentials"**
- Check client ID and secret are correct
- Verify service principal exists in account
- Ensure service principal is in Account admins group

**"Insufficient permissions"**
- Add service principal to Account admins group
- Wait a few minutes for permissions to propagate

**Debug Authentication**
```bash
export TF_LOG=DEBUG
terraform plan
# Look for "Explicit and implicit attributes" in output
```

---

**Next**: Update your `terraform.tfvars` with the credentials and deploy!
