gcloud auth configure-docker us-docker.pkg.dev
docker build -t dlrm_b200:latest .
docker tag dlrm_b200:latest us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200:latest
docker push us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200:latest


docker build -t dlrm_b200_gke:latest .
docker tag dlrm_b200_gke:latest us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200_gke:latest
docker push us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200_gke:latest

export PROJECT=supercomputer-testing
export ZONE=us-central1-b
export INSTANCE_NAME=tonyjohnchen-a4
export RESERVATION_ID=a4-exr-supercomputer-testing

gcloud config set project ${PROJECT}
gcloud config set compute/zone ${ZONE}

# gcloud compute ssh ${INSTANCE_NAME} --zone ${ZONE} --project ${PROJECT} -- -o ProxyCommand='corp-ssh-helper %h %p'

gcloud compute instances attach-disk ${INSTANCE_NAME}  --disk tony-dlrm --mode rw --zone us-central1-b
gcloud compute ssh ${INSTANCE_NAME} --zone ${ZONE} --project ${PROJECT} -- -o ProxyCommand='corp-ssh-helper %h %p'

docker run --gpus all --ulimit=memlock=68719476736 --privileged=true  -v /home/$USER:/workspace  \
-v /mnt/disks/persist:/mnt/disks/persist -it --rm us-west1-docker.pkg.dev/supercomputer-testing/dlrm/dlrm_b200:latest