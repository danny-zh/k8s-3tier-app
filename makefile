include .env
export $(shell sed 's/=.*//' .env)

docker_image_name = dherrera_application
docker_image_tag = latest
docker_container_name = application

.PHONY: hadolint docker_run export_env

hadolint:
	docker run --rm -i hadolint/hadolint < application/Dockerfile

docker_build:
	docker build -t ${docker_image_name}:${docker_image_tag} -f application/Dockerfile application

docker_run: docker_build
	docker rm -f ${docker_container_name} || true && \
	docker run --name ${docker_container_name} -dp 5000:5000 ${docker_image_name}:${docker_image_tag}

docker_remove_container:
	docker rm -f ${docker_container_name} || true

docker_push:
	docker tag ${docker_image_name}:${docker_image_tag} $(DOCKER_USERNAME)/${docker_image_name}:${docker_image_tag}
	echo $(DOCKER_TOKEN) | docker login -u $(DOCKER_USERNAME) --password-stdin
	docker push $(DOCKER_USERNAME)/${docker_image_name}:${docker_image_tag}
	docker logout

docker_compose_up:
	docker compose -f application/docker-compose.yml up -d --build

docker_compose_down:
	docker compose -f application/docker-compose.yml down

docker_prune:
	docker system prune -f

deploy:
	echo -e "--> Checking minikube status" && \
	if [ $(shell minikube status -o json | jq '.Host') = "Stopped" ]; then\
		minikube start;  \
	else \
		echo "Minikube is already running";\
	fi && \
	echo "--> Changing context to minikube-dherrera" && \
	kubectl config use-context minikube-dherrera && \
	echo "--> Applying manifest.yml" && \
	kubectl apply -f manifest.yml -n dherrera && \
	echo "--> Starting container webproxy for localhost:80:80" && \
	docker container ls -f name=webproxy -q | xargs -i docker rm -f {} && \
	docker run --rm --name webproxy -dp 80:80 --network minikube nginx:latest || true && \
	echo "--> Configure nginx webproxy to forward requests to worker node" && \
	docker cp default.conf webproxy:/etc/nginx/conf.d/default.conf && \
	echo "--> Applying nginx webproxy configuration" && \
	docker exec -t webproxy nginx -t && \
	docker exec -t webproxy nginx -s reload && \
	echo "--> Add dherrera.application.com to /etc/hosts file" && \
	echo "$(shell minikube ip) dherrera.application.com" | sudo tee -a /etc/hosts && \
	echo "--> Deployment complete"


destroy:
	if [ $(shell minikube status -o json | jq '.Host') = "Running" ]; then\
		echo "--> Changing context to minikube-dherrera" && \
		kubectl config use-context minikube-dherrera && \
		echo "--> Scaling down sts pods to 0" && \
		sleep 2 && \
		kubectl scale sts mongo --replicas 0 -n dherrera &&  \
		echo "--> Deleting manifest.yml resource" && \
		kubectl delete -f manifest.yml -n dherrera && \
		echo "--> Deleting all resources from dherrera namespace" && \
		kubectl delete all --all -n dherrera && \
		echo "--> Deleting docker container webproxy" && \
		docker container ls -f name=webproxy -q | xargs -i docker rm -f {} &&\
		echo "--> Removing entry dherrera.application.com from /etc/hosts fie" && \
		sudo sed -i '/dherrera.application.com/d' /etc/hosts && \
		echo "--> Deployment destroyed" && \
		echo "--> Changing context to minikube" && \
		kubectl config use-context minikube; \
	else \
		echo "Minikube is Stopped";\
	fi
	