
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsundeep-dayalan%2FMONET%2Fmain%2Fdeployments%2Fazure%2Fazuredeploy.json)


One-click deploy provisions:
- Azure Functions backend (Python) with ZipDeploy of `monet-api.zip`
- Azure Static Web App frontend with deployment of `monet-client.zip` (no GitHub Actions or tokens)

Notes:
- You can optionally set the `releaseVersion` parameter during deployment to pin a specific tag (for example `v1.0.23`). If omitted, `latest` is used.
- The deploy uses a managed identity at runtime to fetch a temporary deployment token and push the built client to Static Web Apps. No secrets are stored in the repo.


git tag v1.0.23 && git push origin v1.0.23




git tag -d v1.0.2
git push origin :refs/tags/v1.0.2
git tag v1.0.3
git push origin v1.0.3


# Create and activate a new virtual environment
python3 -m venv venv
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt