# DevOps BootCamp: Kubernetes Practical Task

We are glad to see you here!

During this course you will become familiar with a lot of tools and technologies. We would like you to apply this knowledge in practice, otherwise it would be boring. There is a task for you, which you can do along with stydying materials from this course. So, without further adieu, let's begin this task!

**Be aware:**
Don't make any changes not in **manifest.yml** file. It can break test logic.

# Description

You need to build the app's container images and deploy them to Kubernetes.

## Requirements

- Installed [jq utility](https://stedolan.github.io/jq/download/) 

## Application Description

The application will be deployed in 3-tier layers:

- Presentation layer: Kubernetes NGINX Ingress;
- Application layer: Flask application based on Docker image in Kubernetes pods;
- Data layer: MongoDB based on Docker image in Kubernetes pods.

The Flask application provides users with possibility to change colour of website background.

## Step Description

### Build application 

The first step of deploying the application is building Docker images and publish it to Docker registry.

Application source code is placed in **application** directory.

You need to fix *Dockerfile* so that Docker image complyes with the following requirements:

- No Hashell Dockerfile linter errors and/or warnings 
- Docker image name is `<nsurname>_application`
- Docker image consists of the application and its requirements
- Docker image might be placed in **private** DockerHub repository `<nsurname>_application`


##### Haskell Dockerfile Linter

Lint, or a linter, is a static code analysis tool used to flag programming errors, bugs, stylistic errors and suspicious constructs.

How to install `hadolint`: [Haskell Dockerfile Linter](https://github.com/hadolint/hadolint#install)

Check if `hadolint` is installed:

```console
$ hadolint --version
Haskell Dockerfile Linter 2.7.0-no-git
```
Run `hadolint` to lint your Dockerfiles and fix errors and warnings if they are.

**Usage Example:**

```console
$ cat Dockerfile 
FROM nginx
ADD info.conf /etc/nginx/conf.d/default.conf

$ hadolint Dockerfile # 2 issues
Dockerfile:1 DL3006 warning: Always tag the version of an image explicitly
Dockerfile:2 DL3020 error: Use COPY instead of ADD for files and folders

$ cat Dockerfile 
FROM nginx:1.21.3
COPY info.conf /etc/nginx/conf.d/default.conf

$ hadolint Dockerfile # no issues
```

##### Private Docker repository

How to create a private repository: [Documentation](https://docs.docker.com/docker-hub/repos/#private-repositories)


### Test: Docker Compose Deployment

The second step is that verify that your application can be deployed as Docker container.

You need to prepare *docker-compose.yaml* that:

- deploys *mongo* container:
    - name: mongo
    - port: 27017
    - username: root
    - password: example
- deploys your application container:
    - name: application
    - port: 5000
    - environment:
        - MONGO_HOST: mongo
        - MONGO_PORT: 27017
        - BG_COLOR: teal


Now you can deploy your application on the local PC and check how it works.

**Step Result:**
- the application is deployed (you can open it in browser)
- issue is fixed on *Issue Page* page
- data can be written to MongoDB on *Test DB Connectivity* page


### Deployment Preparation 

The next step is preparing Kubernetes manifest **manifest.yml** and deploy it to *local* Kubernetes.

Your Kubernetes manifest should meet the following requirements:

- Deploy application layer (your custom Docker image) based on *Deployment* and *Service*:
    - Docker credentials have been gotten from Kubernetes secret
    - Deployment name is *application*
    - Deployment label is *application*
    - Container name is *application*
    - Service name is *application*
    - Service port is *80*
    - Container port is *5000*
    - The number of replicas is *1*
    - Add liveness/readiness probe: liveness probe to path /healthz, readiness probe to path /healthx
    - Deploy strategy "Recreate"
    - Run application with next resources: CPU: limit-0.5 request-0.2, Memory: limit-128Mi request-64Mi
    - The deployment variables were obtained from the Kubernetes configmap *application*
    - Add init container to deployment of app: wait until the mongo is available and running
- Deploy data layer:
    - StatefullSet name is *mongo*
    - StatefullSet label is *mongo*
    - Container name is *mongo*
    - The number of replicas is *1*
    - Run StatefullSet with next resources:
        - CPU: limit-0.5 request-0.2
        - Memory: limit-256Mi request-128Mi
    - Mongo credentials have been gotten from Kubernetes secret mongo
    - Secret name is *mongo*
- Deploy presentation layers based on NGINX Ingress:
    - NGINX Ingress name is *nginx*
    - Host is `<nsurname>.application.com`
    - Port is *80*

**Step Result:**
- the application is deployed in your *local* Kubernetes;
- the application is accessed through `<nsurname>.application.com` URL

### Local Machine Preparation
**Vagrant (optional)**
Vagrantfile can be used for VM provisioning with required tools (Docker, Minikube, Hadolint, Kubectl, etc.).
Otherwise required tools must be installed on your local machine.

Futher elaboration of installing and checking tools can be found in the following sections.

**Minikube (mandatory)**

How to install and run minikube: [minikube start](https://minikube.sigs.k8s.io/docs/start/)

Start Minikube and check if it is running:

To start Minikube run `minikube start --vm-driver=$your_vm_provider` command, where *$your_vm_provider* is your [virtualization product](https://minikube.sigs.k8s.io/docs/drivers/). 
For example:
```console
$ minikube start --vm-driver=hyperkit
...

$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Enable NGINX Ingress in MiniKube and check if it is running:

```console
$ minikube addons enable ingress
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.0.0-beta.3
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled

$ kubectl --context minikube --namespace ingress-nginx get pods
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create--1-n9w2k     0/1     Completed   0          2m26s
ingress-nginx-admission-patch--1-cnx7n      0/1     Completed   0          2m26s
ingress-nginx-controller-69bdbc4d57-f7lfz   1/1     Running     0          2m26s
```

#### Local Kubernetes Environment Preparation

To simulate **Production** environment, you need to create
and configure your personal namespace in the local cluster.

It can get done using `utils/local_minikube_preparation.sh` script.
The script creates cluster resources (namespace, role, config context) based on your full name (the first name charater and last name):

```console
$ utils/local_minikube_preparation.sh "Anton Butsko"
Switched to context "minikube".
namespace/abutsko created
serviceaccount/abutsko created
role.rbac.authorization.k8s.io/abutsko created
rolebinding.rbac.authorization.k8s.io/abutsko created
User "minikube-abutsko" set.
Context "minikube-abutsko" created.
Switched to context "abutsko".
```

To interact with your cluster using created credentials, you need to switch to created context.

Use `kubectl config get-contexts` command to see existed contexts:

```console
$ kubectl config get-contexts 
CURRENT   NAME               CLUSTER         AUTHINFO           NAMESPACE
*         abutsko            cluster.local   abutsko            abutsko
          minikube           minikube        minikube           default
          minikube-abutsko   minikube        minikube-abutsko   abutsko
```

Use `kubectl config use-context <name>` command to change current context:

```console
$ kubectl config use-context minikube-abutsko
Switched to context "minikube-abutsko".
```

Check if your config context is set correctly so that you can interact with your cluster within only your namespace:

```console
$ kubectl config current-context
minikube-abutsko
$ kubectl get pods
No resources found in abutsko namespace.
$ kubectl --namespace default get pods
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:abutsko:abutsko" cannot list resource "pods" in API group "" in the namespace "default"
```

#### Kubernetes Secret Creation

**Usage Example:**
```console
$ kubectl create secret generic docker-secret \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
secret/docker-secret created
```

**Tips:**
- open your deployed application (`/test_db` page) in a browser. To do that you need to think about:
    - how to get cluster/node IP address where NGINX ingress listen to;
    - how to resolve your application DNS name (e.g., abutsko.application.com) to IP from the previous step
- do some request from the form on the page
- if some readiness or liveness checks fail, think about some Probes settings in seconds
- if you have troubles with docker secret investigate [Kubernetes secret documentation](https://kubernetes.io/docs/concepts/configuration/secret/#docker-config-secrets)

**Be aware:**
Possible, you will need to rerun the step of this test since you can reach your application and do some request only when it will be deployed.
So that don't panic if this step failed on the first run.

### Last Step

**Pay attention:**
Automatically test will check only **manifest.yml** correctness. 
Finally task will be checked in the life session with your mentor on your local minikube cluster.
