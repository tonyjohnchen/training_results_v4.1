gcloud auth configure-docker us-docker.pkg.dev
docker build -t dlrm_b200:latest .
docker tag dlrm_b200:latest us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200:latest
docker push us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200:latest


docker build -t dlrm_b200_gke:latest .
docker tag dlrm_b200_gke:latest us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200_gke:latest
docker push us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200_gke:latest