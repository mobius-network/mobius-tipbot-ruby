docker build -t gcr.io/mobius-network/hello-app:${REVISION} .
gcloud docker -- push gcr.io/mobius-network/hello-app:${REVISION}
cat manifests/helloweb-deployment.yaml | sed 's/__REVISION__/'"$REVISION"'/g' > manifests/helloweb-deployment-r.yaml
kubectl apply -f manifests/helloweb-deployment-r.yaml
kubectl apply -f manifests/helloweb-service.yaml
