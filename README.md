# DevoxxFR 2021 edition 9 3/4

**Cloud Native Application Bundle demos**

## General Setup

### Start the local registry

```console
$ make setup-registry
docker volume create local-registry || true
local-registry
docker run -d --name registry --rm -v local-registry:/var/lib/registry -p 5000:5000 registry:2.7
b1b29a04f611ea9702c90f959e76520ac4a8c6a5e33ab357aea1a2c426664b89
```

Now you have a private, local, insecure Docker registry available on `http://127.0.0.1:5000`

### Post Cleanup

Ensure all applications have been deleted, registry stopped and volume deleted.

```console
$ make cleanup
```

## Wordpress

See [readme](./wordpress).

Inside `wordpress/`

1. build
    ```console
    $ make build
    porter build
    Copying porter runtime ===>
    Copying mixins ===>
    Copying mixin terraform ===>
    Copying mixin helm3 ===>
    
    Generating Dockerfile =======>
    
    Writing Dockerfile =======>
    
    Starting Invocation Image Build (eunomie/devoxxfr-installer:v2021.9.75) =======>
    ```

2. publish
    ```console
    $ make publish
    porter publish --insecure-registry --registry 127.0.0.1:5000
    Pushing CNAB invocation image...
    The push refers to repository [127.0.0.1:5000/devoxxfr-installer]
    5c78e81dfb6c: Preparing
    ...
    af9ed0aefcf5: Pushed
    v2021.9.75: digest: sha256:78832b6152b4518fcfce15a5d812818642ca4d6d82d59a7cb9ae54f3d728ad2d size: 3689

    Rewriting CNAB bundle.json...
    Starting to copy image 127.0.0.1:5000/devoxxfr-installer:v2021.9.75...
    Completed image 127.0.0.1:5000/devoxxfr-installer:v2021.9.75 copy
    Bundle tag 127.0.0.1:5000/devoxxfr:v2021.9.75 pushed successfully, with digest "sha256:8d306c5d7b640f102bc3fa99a02717ff66ff1fc3e4424c4a7d82cf316d0f6768"
    ```

3. setup credentials
    ```console
    $ make setup-credentials
    porter credentials generate kubeconfig
    Generating new credential kubeconfig from bundle devoxxfr
    ==> 1 credentials required for bundle devoxxfr
    ? How would you like to set credential "kubeconfig"
    [Use arrows to move, space to select, type to filter]
    secret
    specific value
    environment variable
    > file path
    shell command
    ? Enter the path that will be used to set credential "kubeconfig"
    $HOME/.kube/config
    ```

4. install
    ```console
    $ make install
    porter install devoxxfrdemo --cred kubeconfig --param="context=docker-desktop" --param="namespace=devoxxfr"
    installing devoxxfrdemo...
    executing install action from devoxxfr (installation: devoxxfrdemo)
    No existing bundle state to unpack
    Create application Kubernetes namespace
    Initializing Terraform...
    /usr/bin/terraform terraform init -backend=true -backend-config=secret_suffix=devoxxfr -reconfigure
    ...
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

    Outputs:

    namespace = "devoxxfr"
    Install Wordpress
    /usr/local/bin/helm3 helm3 upgrade --install devoxxfr bitnami/wordpress --namespace devoxxfr --version 12.1.16 --atomic --create-namespace
    WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: *******
    WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: *******
    Release "devoxxfr" does not exist. Installing it now.
    NAME: devoxxfr
    LAST DEPLOYED: Wed Sep 29 12:22:42 2021
    NAMESPACE: devoxxfr
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    ...
    Collecting bundle outputs...
    Packing bundle state...
    execution completed successfully! 
    ```

## Airgap

This is a small application to show the bundle can embed images as well has charts, so everything is contained inside one single bundle.

1. build
   ```console
   $ make build
   porter build
   Copying porter runtime ===>
   Copying mixins ===>
   Copying mixin helm ===>

   Generating Dockerfile =======>

   Writing Dockerfile =======>

   Starting Invocation Image Build (getporter/whalegap-installer:v0.1.0) =======>
   ```

2. publish
   ```console
   $  make publish
   porter publish --insecure-registry --registry 127.0.0.1:5000
   Pushing CNAB invocation image...
   The push refers to repository [127.0.0.1:5000/whalegap-installer]
   3f90f5554302: Preparing
   ...
   3f90f5554302: Pushed
   v0.1.0: digest: sha256:8655bbe837eda83977ec67f1da48bb0efcb91b08689671b9f3c85a454aba0b85 size: 2213

   Rewriting CNAB bundle.json...
   Starting to copy image 127.0.0.1:5000/whalegap-installer:v0.1.0...
   Completed image 127.0.0.1:5000/whalegap-installer:v0.1.0 copy
   Starting to copy image carolynvs/whalesayd@sha256:8b92b7269f59e3ed824e811a1ff1ee64f0d44c0218efefada57a4bebc2d7ef6f...
   Completed image carolynvs/whalesayd@sha256:8b92b7269f59e3ed824e811a1ff1ee64f0d44c0218efefada57a4bebc2d7ef6f copy
   Bundle tag 127.0.0.1:5000/whalegap:v0.1.0 pushed successfully, with digest "sha256:fa78c0c5de30835f574f6161e66aaae595adb4c64731a0e87e350f26d7cc6bbc"
   ```

3. extract and see what's inside the bundle
   ```console
   $ make extract
   porter bundle archive archive/whalegap.tgz --reference 127.0.0.1:5000/whalegap:v0.1.0
   ~/src/github.com/eunomie/devoxxfr-2021/airgap/archive
   ```
