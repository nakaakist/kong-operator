KEYCLOAK_VERSION=9.0.2
KEYCLOAK_OPERATOR_DIR=keycloak/keycloak-operator-$(KEYCLOAK_VERSION)
KONG_VERSION=0.2.6
KONG_OPERATOR_DIR=kong/kong-operator-$(KONG_VERSION)
KONG_IMAGE_NAME=kong-for-kong-operator

.PHONY: cluster
cluster:
	echo "\n\nSetting up keycloak operator...\n\n"
	if [ ! -d $(KEYCLOAK_OPERATOR_DIR) ]; then \
		curl -LO https://github.com/keycloak/keycloak-operator/archive/$(KEYCLOAK_VERSION).tar.gz; \
		tar -zxvf $(KEYCLOAK_VERSION).tar.gz; \
		rm -rf $(KEYCLOAK_VERSION).tar.gz; \
		mv keycloak-operator-$(KEYCLOAK_VERSION) $(KEYCLOAK_OPERATOR_DIR); \
	fi
	kubectl apply -f $(KEYCLOAK_OPERATOR_DIR)/deploy/crds/
	kubectl apply -f $(KEYCLOAK_OPERATOR_DIR)/deploy/role.yaml
	kubectl apply -f $(KEYCLOAK_OPERATOR_DIR)/deploy/role_binding.yaml
	kubectl apply -f $(KEYCLOAK_OPERATOR_DIR)/deploy/service_account.yaml
	kubectl apply -f $(KEYCLOAK_OPERATOR_DIR)/deploy/operator.yaml
	echo "\n\nSetting up kong operator...\n\n"
	if [ ! -d $(KONG_OPERATOR_DIR) ]; then \
		curl -LO https://github.com/Kong/kong-operator/archive/v$(KONG_VERSION).tar.gz; \
		tar -zxvf v$(KONG_VERSION).tar.gz; \
		rm -rf v$(KONG_VERSION).tar.gz; \
		mv kong-operator-$(KONG_VERSION) $(KONG_OPERATOR_DIR); \
	fi
	kubectl apply -f $(KONG_OPERATOR_DIR)/deploy/crds/charts_v1alpha1_kong_crd.yaml
	kubectl apply -f $(KONG_OPERATOR_DIR)/deploy/

.PHONY: clean
clean:
	kubectl delete -f $(KEYCLOAK_OPERATOR_DIR)/deploy/operator.yaml
	kubectl get roles,rolebindings,serviceaccounts keycloak-operator --no-headers=true -o name | xargs kubectl delete
	kubectl get crd --no-headers=true -o name | awk '/keycloak.org/{print $1}' | xargs kubectl delete
	kubectl delete -f $(KONG_OPERATOR_DIR)/deploy/
	kubectl delete -f $(KONG_OPERATOR_DIR)/deploy/crds/charts_v1alpha1_kong_crd.yaml

.PHONY: kong-image
kong-image:
	echo "\n\nbuilding docker image for kong...\n\n"
	docker image build -t ${KONG_IMAGE_NAME} ./kong/build

.PHONY: upload-kong-image-for-kind
upload-kong-image-for-kind:
	kind load docker-image ${KONG_IMAGE_NAME}

.PHONY: kong
kong: kong-image upload-kong-image-for-kind
	echo "\n\ndeploying kong resources...\n\n"
	kubectl create configmap kong-plugin-oidc --from-file kong/plugins/oidc
	kubectl apply -f kong/

.PHONY: clean-kong
clean-kong:
	kubectl delete configmap kong-plugin-oidc
	kubectl delete -f kong/
