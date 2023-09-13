# Keycloak Proxy Integration Demo

If it doesn't respond to 127.0.0.1, then modify your DNS hosts file accordingly

```bash
nslookup local-keycloak.kong-lab-20.net
# Non-authoritative answer:
# Name:	local-keycloak.kong-lab-20.net
# Address: 127.0.0.1
```

Generate certificates for hybrid deployment

Create self-signed Root CA

```bash
mkdir cluster

openssl ecparam -genkey -name prime256v1 -out ./cluster/cluster-ca.key
openssl req -new -x509 -key ./cluster/cluster-ca.key -out ./cluster/cluster-ca.pem -sha256 -days 3650 -subj "/C=SG/ST=Singapore/L=Singapore/O=Kong Inc/OU=/CN=Kong Root CA"

openssl x509 -in ./cluster/cluster-ca.pem -text -noout
```

Create certificate for Control Plane


```bash
openssl ecparam -genkey -name prime256v1 -out ./cluster/control-plane.key

openssl req -new -key ./cluster/control-plane.key -out ./cluster/control-plane-csr.pem -sha256 -subj "/C=SG/ST=Singapore/L=Singapore/O=Kong Inc/OU=/CN=kong-cp" -addext "subjectAltName=DNS:localhost,DNS:kong_clustering"

openssl x509 -req -in ./cluster/control-plane-csr.pem -out ./cluster/control-plane.pem -CA ./cluster/cluster-ca.pem -CAkey ./cluster/cluster-ca.key -sha256 -days 3650

rm ./cluster/control-plane-csr.pem
```

Create certificate for Data Plane

```bash
openssl ecparam -genkey -name prime256v1 -out ./cluster/data-plane.key

openssl req -new -key ./cluster/data-plane.key -out ./cluster/data-plane-csr.pem -sha256 -subj "/C=SG/ST=Singapore/L=Singapore/O=Kong Inc/OU=/CN=kong-dp1"

openssl x509 -req -in ./cluster/data-plane-csr.pem -out ./cluster/data-plane.pem -CA ./cluster/cluster-ca.pem -CAkey ./cluster/cluster-ca.key -sha256 -days 3650

rm ./cluster/data-plane-csr.pem
```

Launch the components

```bash
export KONG_LICENSE_DATA=<INSERT KONG LICENSE JSON>
docker compose up -d
```

Access keycloak in http://local-keycloak.kong-lab-20.net:8080. Login is `admin` and password is `admin`

Observe that:
- You are in **Kong** realm
- There is a client called `kong`
- In the `kong` client
  - Access type is `confidential`
  - In credentials tab, client authenticator is set as `Client Id and Secret` and the Secret is set

## JWT Access (Bearer) Token Authentication

Setting up plugin:

Common:
* Client ID: `kong`
* Client Secret: `681d81ee-9ff0-438a-8eca-e9a4f892a96b`
* Issuer: `http://local-keycloak.kong-lab-20.net:8080/auth/realms/kong`
* Auth Methods: `Bearer Access Token`

Advanced:
* Config.Consumer By: `username`
* Config.Consumer Claim: `preferred_username`

Or you can just sync using Deck

```bash
deck sync --kong-addr http://localhost:8001 -w keycloak_demo -s kong-oidc-jwt.yaml
```

Accessing the endpoint will give `401 Unauthorized` error

```bash
http localhost:8000/jwt-access-test
```

Retrieve the access token by logging in directly to Keycloak

```bash
# Need to request scope = openid, as Kong's OIDC plugin expects it (refer to scope config)
BEARER_TOKEN=$(http -b -f POST http://local-keycloak.kong-lab-20.net:8080/auth/realms/kong/protocol/openid-connect/token grant_type=password client_id=kong client_secret=681d81ee-9ff0-438a-8eca-e9a4f892a96b scope=openid username=employee password=test | jq -r .access_token)

echo $BEARER_TOKEN
```

Now you will receive `200`

```bash
http -v localhost:8000/jwt-access-test Authorization:"Bearer $BEARER_TOKEN"

# With Session
http -v --session=employee localhost:8000/jwt-access-test Authorization:"Bearer $BEARER_TOKEN"

# See the session
cat ~/.config/httpie/sessions/localhost_8000/employee.json | jq .

# Make request with a session cookie
http -v --session=employee localhost:8000/jwt-access-test
```
