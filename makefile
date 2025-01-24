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