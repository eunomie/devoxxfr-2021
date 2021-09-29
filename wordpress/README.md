# Demo

The demo application is simply Wordpress deployed to an existing Kubernetes
cluster. The installation process is intentionally convoluted to show how tools
can be chained together using Porter and CNAB.

The installation process is as follows:
1. Terraform is used to create a namespace that is specified as a parameter.
1. Helm is used to install Wordpress into this namespace.

## Running the demo

### Prerequisites

* Windows or macOS
  * [Docker Desktop](https://www.docker.com/get-started)
* Linux
  * [Docker Engine](https://www.docker.com/get-started)
  * Access to a Kubernetes cluster
* [Porter](https://porter.sh/install/)

If using Docker Desktop, ensure that you
[turn on Kubernetes](https://docs.docker.com/docker-for-windows/#kubernetes)
before starting.

### Demo steps

### Inspect the bundle

You can get information about the bundle using the `porter bundle explain`
command:

```console
$ porter bundle explain
Name: devoxxfr
Description: DevoxxFR 2021 9 3/4 demo
Version: 2021.9.75
Porter Version: v1.0.0-alpha.3

Credentials:
Name         Description                                                                Required   Applies To
kubeconfig   Kubernetes config to use for creation of namespace and deployment of app   true       All Actions

Parameters:
Name        Description                                            Type     Default          Required   Applies To
context     Context in the Kubernetes config to use                string   docker-desktop   false      All Actions
namespace   Kubernetes namespace to create and deploy app within   string   devoxx           false      All Actions

Outputs:
Name        Description                                 Type     Applies To
namespace   Kubernetes namespace created by Terraform   string   install

This bundle uses the following tools: helm3, terraform.
```

This shows what credentials are required to deploy and manage the application,
what parameters one can modify, and outputs that CNAB actions can generate.

#### Generate a credential set

In order for our application bundle to access your Kubernetes cluster, you will
need to create a credential set with a Kubernetes config file.
In the same directory that you have your `porter.yaml`, run:

```console
$ porter credentials generate kubeconfig
Generating new credential kubeconfig from bundle devoxxfr
==> 1 credentials required for bundle devoxxfr
? How would you like to set credential "kubeconfig"
   [Use arrows to move, space to select, type to filter]
  secret
  specific value
> environment variable
  file path
  shell command
```

Select `file path` and then enter the path to your Kubernetes config file:

```console
? How would you like to set credential "kubeconfig"
  file path
? Enter the path that will be used to set credential "kubeconfig"
$HOME/.kube/config
```

You can verify that you have created a `kubeconfig` credential set as follows:

```console
$ porter credentials list
NAMESPACE   NAME         MODIFIED
            kubeconfig   2 seconds ago
```

#### Install the bundle

To install the application to your Kubernetes cluster, you will use the
`porter install` command. You will also need to pass which credential set to use
and optionally the parameters you would like to change.

```console
$ porter install devoxxfrdemo --cred kubeconfig --param="context=docker-desktop" --param="namespace=devoxxfr"
```

Porter can show you which CNABs you have installed:

```console
$ porter list
NAMESPACE   NAME           CREATED        MODIFIED       LAST ACTION   LAST STATUS
            devoxxfrdemo   1 minute ago   1 minute ago   install       succeeded
```

You can check that the `kubecon` namespace was created on your Kubernetes
cluster:

```console
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   27h
devoxxfr          Active   80s
kube-node-lease   Active   27h
kube-public       Active   27h
kube-system       Active   27h
```

You should also see the Wordpress components starting to come up in the
`devoxxfr` namespace:

```console
$ kubectl get all --namespace devoxxfr
NAME                                      READY   STATUS    RESTARTS   AGE
pod/devoxxfr-mariadb-0                    1/1     Running   0          105s
pod/devoxxfr-wordpress-665d7c9cdc-c9cx8   1/1     Running   0          105s

NAME                         TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/devoxxfr-mariadb     ClusterIP      10.108.183.13    <none>        3306/TCP                     105s
service/devoxxfr-wordpress   LoadBalancer   10.100.253.122   localhost     80:30426/TCP,443:32578/TCP   105s

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/devoxxfr-wordpress   1/1     1            1           105s

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/devoxxfr-wordpress-665d7c9cdc   1         1         1       105s

NAME                                READY   AGE
statefulset.apps/devoxxfr-mariadb   1/1     105s
```

Once all the components are running, and if you are using Docker Desktop, you
will be able to navigate to Wordpress at `http://localhost:80`. If using a
remote Kubernetes, you will find the application at your LoadBalancer address.

#### Uninstall the bundle

To uninstall the application, you will need to give the bundle access to your
Kubernetes credentials:

```console
$ porter uninstall myapp --cred kubeconfig
```

Once this has been run, the `kubecon` namespace should no longer exist:

```console
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   27h
kube-node-lease   Active   27h
kube-public       Active   27h
kube-system       Active   27h
```

#### Publish the bundle to a container registry

To share the CNAB, you can push it to a container registry like
[Docker Hub](https://hub.docker.com). This is done using the `porter publish`
command. Note that you will need to replace `ccrone` with your own Docker Hub
user handle:

```console
$ porter publish
```

Others can then install use your CNAB package directly from the Docker Hub:

```console
$ porter install myregistryapp --cred kubeconfig --reference eunomie/devoxxfr:v2021.9.75
```

You can check as you did that the application has been installed, this time
named `myregistryapp`:

```console
$ porter list
NAME            CREATED          MODIFIED         LAST ACTION   LAST STATUS
myregistryapp   39 seconds ago   33 seconds ago   install       succeeded
```

Finally you can remove the application as you did before:

```console
$ porter uninstall myregistryapp --cred kubeconfig
```

#### Store the bundle for offline use

CNAB bundles can also be stored offline for use in air gapped situations.
Porter provides the `porter bundle archive` command to generate a tarball of the
application package.

```console
$ mkdir -p archive
$ porter bundle archive --reference eunomie/devoxxfr:v2021.9.75 archive/archive.tgz
```

You can extract the tarball to see the CNAB inside:

```console
$ cd archive/
$ tar xzf archive.tgz
$ ls
artifacts           bundle.json         archive.tgz
```

Inside the artifacts directory is an
[OCI image layout](https://github.com/opencontainers/image-spec/blob/v1.0.1/image-layout.md)
of the registry representation of the invocation image from the CNAB.
Note that Porter exports a "thin" bundle which excludes the component container
images that make up Wordpress in this instance.

Porter abstracts the complexity of the CNAB specification implementation from
the user. You can see the
[CNAB bundle file](https://github.com/cnabio/cnab-spec/blob/cnab-core-1.0.1/101-bundle-json.md),
the `bundle.json`, here though:

```console
$ cat bundle.json | jq .
```
```json
{
  "credentials": {
    "kubeconfig": {
      "description": "Kubernetes config to use for creation of namespace and deployment of app",
      "path": "/root/.kube/config",
      "required": true
    }
  },
  "custom": {
    "io.cnab.parameter-sources": {
      "porter-namespace-output": {
        "priority": [
          "output"
        ],
        "sources": {
          "output": {
            "name": "namespace"
          }
        }
      },
      "porter-state": {
        "priority": [
          "output"
        ],
        "sources": {
          "output": {
            "name": "porter-state"
          }
        }
      }
    },
    "sh.porter": {
      "commit": "09840b4c",
      "manifest": "IyBJbnN0YWxsaW5nIHRoaXMgYXBwbGljYXRpb24gd2lsbCB5aWVsZCBhIHNpbXBsZSBXb3JkcHJlc3MgYmxvZyBvbiBhbiBleGlzdGluZwojIEt1YmVybmV0ZXMgY2x1c3Rlci4KIyBUaGUgcHJvY2VzcyBvZiBpbnN0YWxsaW5nIGludm9sdmVzOgojIC0gQ3JlYXRpbmcgYSBuZXcgbmFtZXNwYWNlIHVzaW5nIFRlcnJhZm9ybQojIC0gRGVwbG95aW5nIFdvcmRwcmVzcyBpbnRvIHRoaXMgbmFtZXNwYWNlIHVzaW5nIEhlbG0KCiMgQXBwbGljYXRpb24gbWV0YWRhdGEuCm5hbWU6IGRldm94eGZyCnZlcnNpb246IDIwMjEuOS43NQpkZXNjcmlwdGlvbjogIkRldm94eEZSIDIwMjEgOSAzLzQgZGVtbyIKcmVnaXN0cnk6IGV1bm9taWUKCiMgVGhlIHRvb2xzIHRoYXQgYXJlIHJlcXVpcmVkIHRvIGRlcGxveSB0aGlzIGFwcGxpY2F0aW9uLgojIEEgbGlzdCBvZiBtaXhpbnMgY2FuIGJlIGZvdW5kIGhlcmU6IGh0dHBzOi8vcG9ydGVyLnNoL21peGlucy8KbWl4aW5zOgogIC0gdGVycmFmb3JtOgogICAgICBjbGllbnRWZXJzaW9uOiAxLjAuNwogICAgICBpbml0RmlsZTogcHJvdmlkZXJzLnRmCiAgLSBoZWxtMzoKICAgICAgcmVwb3NpdG9yaWVzOgogICAgICAgIGJpdG5hbWk6CiAgICAgICAgICB1cmw6ICJodHRwczovL2NoYXJ0cy5iaXRuYW1pLmNvbS9iaXRuYW1pIgoKIyBDcmVkZW50aWFscyBhcmUgc2Vuc2l0aXZlIGluZm9ybWF0aW9uIHJlcXVpcmVkIHRvIGRlcGxveSB0aGUgYXBwbGljYXRpb24uCiMgVGhlcmUgaXMgb25lIHNldCBvZiBjcmVkZW50aWFscyBsaXN0ZWQgaGVyZSBhcyByZXF1aXJlZCBmb3IgdGhlIGFwcGxpY2F0aW9uOgojIC0gQSBLdWJlcm5ldGVzIGNvbmZpZyBmaWxlIHRoYXQgaXMgbW91bnRlZCB0byBgL3Jvb3QvLmt1YmUvY29uZmlnYCBpbiB0aGUKIyAgIENOQUIgaW5zdGFsbGVyLgpjcmVkZW50aWFsczoKICAtIG5hbWU6IGt1YmVjb25maWcKICAgIGRlc2NyaXB0aW9uOiAiS3ViZXJuZXRlcyBjb25maWcgdG8gdXNlIGZvciBjcmVhdGlvbiBvZiBuYW1lc3BhY2UgYW5kIGRlcGxveW1lbnQgb2YgYXBwIgogICAgcGF0aDogL3Jvb3QvLmt1YmUvY29uZmlnCgojIFBhcmFtZXRlcnMgYXJlIHVzZXIgc2V0dGluZ3MgdGhhdCBhcmUgdXNlZCB0byBjb25maWd1cmUgdGhlIGFwcGxpY2F0aW9uLgojIFRoZXJlIGFyZSB0d28gcGFyYW1ldGVycyBsaXN0ZWQgaGVyZToKIyAtIFRoZSBLdWJlcm5ldGVzIGNvbnRleHQgdG8gdXNlIChkZWZhdWx0OiBkb2NrZXItZGVza3RvcCkKIyAtIFRoZSBLdWJlcm5ldGVzIG5hbWVzcGFjZSB0byBjcmVhdGUgYW5kIHVzZSBmb3IgdGhpcyBhcHBsaWNhdGlvbgojICAgKGRlZmF1bHQ6IGRldm94eCkKcGFyYW1ldGVyczoKICAtIG5hbWU6IGNvbnRleHQKICAgIGRlc2NyaXB0aW9uOiAiQ29udGV4dCBpbiB0aGUgS3ViZXJuZXRlcyBjb25maWcgdG8gdXNlIgogICAgdHlwZTogc3RyaW5nCiAgICBkZWZhdWx0OiAiZG9ja2VyLWRlc2t0b3AiCiAgLSBuYW1lOiBuYW1lc3BhY2UKICAgIGRlc2NyaXB0aW9uOiAiS3ViZXJuZXRlcyBuYW1lc3BhY2UgdG8gY3JlYXRlIGFuZCBkZXBsb3kgYXBwIHdpdGhpbiIKICAgIHR5cGU6IHN0cmluZwogICAgZGVmYXVsdDogImRldm94eCIKCiMgT3V0cHV0cyBhcmUgY29sbGVjdGVkIGZyb20gYSBzdGFnZSBpbiBhIENOQUIgYWN0aW9uLiBUaGlzIGFsbG93cyBjYXB0dXJpbmcKIyBpbmZvcm1hdGlvbiBmcm9tIG9uZSBzdGFnZSAoZS5nLjogYSBVUkwpIGFuZCB1c2luZyBpdCBpbiBhbm90aGVyLgojIEluIHRoaXMgY2FzZSB3ZSBoYXZlIGEgc2luZ2xlIG91dHB1dDoKIyAtIG5hbWVzcGFjZSB0aGF0IGlzIGZpbGxlZCBieSB0aGUgVGVycmFmb3JtIGluc3RhbGwgc3RlcC4Kb3V0cHV0czoKICAtIG5hbWU6IG5hbWVzcGFjZQogICAgZGVzY3JpcHRpb246ICJLdWJlcm5ldGVzIG5hbWVzcGFjZSBjcmVhdGVkIGJ5IFRlcnJhZm9ybSIKICAgIHR5cGU6IHN0cmluZwogICAgYXBwbHlUbzoKICAgICAgLSBpbnN0YWxsICMgV2Ugd2lsbCBvbmx5IGZpbGwgdGhpcyBvdXRwdXQgaW4gdGhlIGluc3RhbGwgYWN0aW9uLgoKIyBUaGUgaW5zdGFsbCBhY3Rpb24gZGVmaW5lcyB0aGUgc3RlcHMgcmVxdWlyZWQgdG8gaW5zdGFsbCB0aGUgYXBwbGljYXRpb24uCiMgSW4gdGhpcyBjYXNlLCB3ZSBzdGFydCBieSBjcmVhdGluZyBhIEt1YmVybmV0ZXMgbmFtZXNwYWNlIHVzaW5nIFRlcnJhZm9ybS4KIyBUaGUgbmFtZSBvZiB0aGUgbmFtZXNwYWNlIGlzIGEgcGFyYW1ldGVyIHdpdGggYSBkZWZhdWx0IHZhbHVlIG9mICJrdWJlY29uIi4KIyBPbmNlIHRoZSBuYW1lc3BhY2UgaGFzIGJlZW4gY3JlYXRlZCwgSGVsbSBpcyB1c2VkIHRvIGluc3RhbGwgV29yZHByZXNzIGludG8KIyB0aGUgbmFtZXNwYWNlLiBOb3RlIHRoYXQgdGhlIFRlcnJhZm9ybSBzdGVwIG91dHB1dHMgdGhlIG5hbWVzcGFjZSBuYW1lIGFuZAojIHRoYXQgdGhpcyBpcyB1c2VkIGJ5IHRoZSBIZWxtIHN0ZXAuCmluc3RhbGw6CiAgLSB0ZXJyYWZvcm06CiAgICAgIGRlc2NyaXB0aW9uOiAiQ3JlYXRlIGFwcGxpY2F0aW9uIEt1YmVybmV0ZXMgbmFtZXNwYWNlIgogICAgICBiYWNrZW5kQ29uZmlnOgogICAgICAgICMgQ29uZmlndXJlIHRoZSBUZXJyYWZvcm0gYmFja2VuZCB0byB1c2UgYSBLdWJlcm5ldGVzIHNlY3JldCBmb3Igc3RhdGUKICAgICAgICAjIHdpdGggdGhlIGJ1bmRsZSBuYW1lIGFzIGl0cyBwcmVmaXguCiAgICAgICAgc2VjcmV0X3N1ZmZpeDogInt7IGJ1bmRsZS5uYW1lIH19IgogICAgICB2YXJzOgogICAgICAgIGNvbnRleHQ6ICJ7eyBidW5kbGUucGFyYW1ldGVycy5jb250ZXh0IH19IgogICAgICAgIG5hbWVzcGFjZTogInt7IGJ1bmRsZS5wYXJhbWV0ZXJzLm5hbWVzcGFjZSB9fSIKICAgICAgb3V0cHV0czoKICAgICAgICAtIG5hbWU6IG5hbWVzcGFjZQogIC0gaGVsbTM6CiAgICAgIGRlc2NyaXB0aW9uOiAiSW5zdGFsbCBXb3JkcHJlc3MiCiAgICAgIG5hbWU6ICJ7eyBidW5kbGUubmFtZSB9fSIKICAgICAgbmFtZXNwYWNlOiAie3sgYnVuZGxlLm91dHB1dHMubmFtZXNwYWNlIH19IgogICAgICBjaGFydDogYml0bmFtaS93b3JkcHJlc3MKICAgICAgdmVyc2lvbjogMTIuMS4xNgogICAgICB1cHNlcnQ6IGZhbHNlCgojIFRoZSB1cGdyYWRlIGFjdGlvbiBzaW1wbHkgdXNlcyBIZWxtIHRvIHVwZ3JhZGUgV29yZHByZXNzIHRvIHRoZSBsYXRlc3Qgc3RhYmxlCiMgdmVyc2lvbi4KdXBncmFkZToKICAtIGhlbG0zOgogICAgICBkZXNjcmlwdGlvbjogIlVwZ3JhZGUgV29yZHByZXNzIgogICAgICBuYW1lOiAie3sgYnVuZGxlLm5hbWUgfX0iCiAgICAgIG5hbWVzcGFjZTogInt7IGJ1bmRsZS5vdXRwdXRzLm5hbWVzcGFjZSB9fSIKICAgICAgY2hhcnQ6IGJpdG5hbWkvd29yZHByZXNzCgojIFRoZSB1bmluc3RhbGwgYWN0aW9uIHN0YXJ0cyBieSB1c2luZyBIZWxtIHRvIHJlbW92ZSBXb3JkcHJlc3MgYW5kIHRoZW4gdXNlcwojIFRlcnJhZm9ybSB0byByZW1vdmUgdGhlIG5hbWVzcGFjZSB3ZSBjcmVhdGVkLgp1bmluc3RhbGw6CiAgLSBoZWxtMzoKICAgICAgZGVzY3JpcHRpb246ICJVbmluc3RhbGwgV29yZHByZXNzIgogICAgICBwdXJnZTogdHJ1ZQogICAgICByZWxlYXNlczoKICAgICAgICAtICJ7eyBidW5kbGUubmFtZSB9fSIKICAtIHRlcnJhZm9ybToKICAgICAgZGVzY3JpcHRpb246ICJSZW1vdmUgYXBwbGljYXRpb24gS3ViZXJuZXRlcyBuYW1lc3BhY2UiCiAgICAgIGJhY2tlbmRDb25maWc6CiAgICAgICAgIyBDb25maWd1cmUgdGhlIFRlcnJhZm9ybSBiYWNrZW5kIHRvIHVzZSBhIEt1YmVybmV0ZXMgc2VjcmV0IGZvciBzdGF0ZQogICAgICAgICMgd2l0aCB0aGUgYnVuZGxlIG5hbWUgYXMgaXRzIHByZWZpeC4KICAgICAgICBzZWNyZXRfc3VmZml4OiAie3sgYnVuZGxlLm5hbWUgfX0iCiAgICAgIHZhcnM6CiAgICAgICAgY29udGV4dDogInt7IGJ1bmRsZS5wYXJhbWV0ZXJzLmNvbnRleHQgfX0iCiAgICAgICAgbmFtZXNwYWNlOiAie3sgYnVuZGxlLm91dHB1dHMubmFtZXNwYWNlIH19Igo=",
      "manifestDigest": "afe393f33fd4381167dc0b254f23770494b9f08aa8ed56c2c3cdfa8768248942",
      "mixins": {
        "helm3": {},
        "terraform": {}
      },
      "version": "v1.0.0-alpha.3"
    },
    "sh.porter.file-parameters": {}
  },
  "definitions": {
    "context-parameter": {
      "default": "docker-desktop",
      "description": "Context in the Kubernetes config to use",
      "type": "string"
    },
    "namespace-output": {
      "description": "Kubernetes namespace created by Terraform",
      "type": "string"
    },
    "namespace-parameter": {
      "default": "devoxx",
      "description": "Kubernetes namespace to create and deploy app within",
      "type": "string"
    },
    "porter-debug-parameter": {
      "$comment": "porter-internal",
      "$id": "https://porter.sh/generated-bundle/#porter-debug",
      "default": false,
      "description": "Print debug information from Porter when executing the bundle",
      "type": "boolean"
    },
    "porter-namespace-output": {
      "$comment": "porter-internal",
      "$id": "https://porter.sh/generated-bundle/#porter-parameter-source-definition",
      "description": "Kubernetes namespace created by Terraform",
      "type": "string"
    },
    "porter-state": {
      "$comment": "porter-internal",
      "$id": "https://porter.sh/generated-bundle/#porter-state",
      "contentEncoding": "base64",
      "description": "Supports persisting state for bundles. Porter internal parameter that should not be set manually.",
      "type": "string"
    }
  },
  "description": "DevoxxFR 2021 9 3/4 demo",
  "invocationImages": [
    {
      "contentDigest": "sha256:1a432f0c9f508de4bb58b4c45060a7ff09ec0972ecb8d304ec0364d4c2a21968",
      "image": "127.0.0.1:5000/devoxxfr-installer:v2021.9.75",
      "imageType": "docker",
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 3689
    }
  ],
  "name": "devoxxfr",
  "outputs": {
    "namespace": {
      "applyTo": [
        "install"
      ],
      "definition": "namespace-output",
      "description": "Kubernetes namespace created by Terraform",
      "path": "/cnab/app/outputs/namespace"
    },
    "porter-state": {
      "definition": "porter-state",
      "description": "Supports persisting state for bundles. Porter internal parameter that should not be set manually.",
      "path": "/cnab/app/outputs/porter-state"
    }
  },
  "parameters": {
    "context": {
      "definition": "context-parameter",
      "description": "Context in the Kubernetes config to use",
      "destination": {
        "env": "CONTEXT"
      }
    },
    "namespace": {
      "definition": "namespace-parameter",
      "description": "Kubernetes namespace to create and deploy app within",
      "destination": {
        "env": "NAMESPACE"
      }
    },
    "porter-debug": {
      "definition": "porter-debug-parameter",
      "description": "Print debug information from Porter when executing the bundle",
      "destination": {
        "env": "PORTER_DEBUG"
      }
    },
    "porter-namespace-output": {
      "definition": "porter-namespace-output",
      "description": "Wires up the namespace output for use as a parameter. Porter internal parameter that should not be set manually.",
      "destination": {
        "env": "PORTER_NAMESPACE_OUTPUT"
      }
    },
    "porter-state": {
      "definition": "porter-state",
      "description": "Supports persisting state for bundles. Porter internal parameter that should not be set manually.",
      "destination": {
        "path": "/porter/state.tgz"
      }
    }
  },
  "requiredExtensions": [
    "sh.porter.file-parameters",
    "io.cnab.parameter-sources"
  ],
  "schemaVersion": "v1.0.0",
  "version": "2021.9.75"
}
```

## Files

### porter.yaml

The [`porter.yaml`](./porter.yaml) is a manifest where one can define what tools
and steps are required for installing, upgrading, and uninstalling the
application. Detailed documentation about this can be found
[here](https://porter.sh/author-bundles/).

Each section of the demo [`porter.yaml`](./porter.yaml) has comments explaining
them.

### terraform/

Comments can be found inside the Terraform files:

- [terraform/main.tf](./terraform/main.tf)
- [terraform/outputs.tf](./terraform/outputs.tf)
- [terraform/variables.tf](./terraform/variables.tf)
- [terraform/providers.tf](./terraform/providers.tf)

# Thanks

Special thanks to Chris Crone and his Kubecon '20 demo available here: https://github.com/chris-crone/kubecon-eu-20
