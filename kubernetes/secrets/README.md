Managing kubernetes secrets
===========================

Application secrets are stored in the kubernetes secrets management system, where the secrets can be supplied at runtime via environment variables.

## Adding dev secrets to minikube
1. Copy `secrets.env-dev` to `secrets.env`
2. Modify settings if necessary
3. Make sure your minikube cluster is running and your `kubectl` context is set
4. Run `kubectl apply -k .`

## Adding a new secret for the application to use in staging/production
1. Add the new secret to `secrets.env-dev` with a dev-specific value
2. Pass the secrets to the ops team through a secure channel (lastpass, keybase, etc.)
3. Ask the ops team to add the new secret to staging and production (preferably different values for each env)
(There should be an item in lastpass called "<Application>-<Environment>-k8s-secrets.env"

## Adding a new secret to staging / production kuberenetes
(Similar to the dev process)
1. Download the `secrets.env` and `settings.ini` for the correct environment from lastpass
2. Make sure your `kubectl` context is set to the proper environment
3. Run `kubectl apply -k .`  (Change the namespace if necessary using `-n <namespace>`)

When the secrets are stored in kubernetes, you can make them available to the application by editing the `deployment.yaml` file and adding an env var in the `env` section:
```
        - name: TOP_SECRET_API_KEY
          valueFrom:
            secretKeyRef:
              name: myApplication
              key: TOP_SECRET_API_KEY
```

In this case, `TOP_SECRET_API_KEY` will be exposed to the application, and `myApplication` should be the name of the secret from the `kustomization.yaml` file. For example, `<% .Name %>`.

An example `secrets.env` would look like:

```
DATABASE_USERNAME=user
DATABASE_PASSWORD=pass
```
