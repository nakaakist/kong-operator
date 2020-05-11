# Test of Kong operator
テスト環境: minikube
## Install
まず、minikubeを立ち上げる。

その後、Operator Lifecycle Managerを以下のコマンドでインストール
```
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.14.1/install.sh | bash -s 0.14.1
```
その後、KongのOperatorを以下のコマンドでインストール。
```
kubectl create -f https://operatorhub.io/install/kong.yaml
```
その後、このリポジトリに移動し、
```
kubectl apply -f .
```
とする。

`minikube ip`でminikubeのノードのIPを調べ、`kubectl get svc`で`example-kong-kong-proxy`がlistenしているポートを調べて、
```
curl (minikubeのIP):(example-kong-kong-proxyのポート)/json-server-1/posts
```
あるいは
```
curl (minikubeのIP):(example-kong-kong-proxyのポート)/json-server-2/posts
```
などとしてAPIにアクセスする。