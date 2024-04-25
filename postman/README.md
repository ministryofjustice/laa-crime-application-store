# POSTMAN Tests

Manually running against branch build instances

1. Download the postman application - or use web front end
2. Import the postman collection
3. Setup the required varibles in the collection environment (see below)
4. Run the tests

## Setting up variables

The easiest way to configure the required varibles in postman is to copy them
from the kubectl config for provider or caseworker application using the below command:

```
kubectl -n laa-submit-crime-forms-dev get secrets azure-secret -oyaml
```

Adding the following varibles to the environment config in postman:

* baseUrl -> update to point to new deployed url
* applicationId -> from app_client_id
* tenantId -> from tenant_id
* applicationSecret -> from app_client_secret

> **NOTE:** It is also necessary to ensure the `tokenExpires` variable has a value
> as if it is left as an empty string the access token **will not** be updated.
