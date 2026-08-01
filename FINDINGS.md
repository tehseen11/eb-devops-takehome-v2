

## Defect 1

**Symptom** (what you observed — paste the real command output):

```
./scenario.sh verify

FAIL  migrate Job has not completed (does it exist? did the chart even install cleanly?)
FAIL  deployment backend: 0/1 ready
FAIL  deployment gateway: 0/1 ready
FAIL  deployment worker: 0/1 ready
FAIL  deployment reporter: 0/1 ready
FAIL  deployment metrics: 0/1 ready
FAIL  backend does not answer on http://backend:8080/healthz
FAIL  gateway /status does not report backend=ok
FAIL  reporter /report does not return a pod count
```

**Cause** (the actual root cause, not the symptom restated):

The application containers were configured to run on port 8081, but the Helm chart configured the Kubernetes container port, readiness probes, and target ports using port 8080.

The backend container logs showed:

```
2026/08/01 12:23:16 eb-debug-app 2.0.0 starting: mode=api pod=backend-5bf7d6d4c5-9zgrs listening on :8081 (image default is 8081; set PORT to override)
```

Kubernetes readiness probes were checking port 8080, causing connection failures.

**Fix** (what you changed, and why this over alternatives):

Updated `broken-chart/values.yaml`:

```yaml
common:
  port: 8081
```

The Kubernetes Services continued exposing port 8080 while forwarding traffic to container port 8081.

This approach was chosen because the application was already correctly running on port 8081. Changing the Helm configuration was safer than modifying application runtime behavior.

**How I found it** (the sequence of commands/reasoning that led you here):

1. Checked failing workloads:

```bash
kubectl get pods -n debug-lab -o wide
```

2. Inspected backend pod details:

```bash
kubectl describe pod backend-5bf7d6d4c5-9zgrs -n debug-lab
```

3. Found readiness failure:

```
Readiness probe failed:
dial tcp 10.244.0.45:8080: connect: connection refused
```

4. Checked application logs:

```bash
kubectl logs backend-5bf7d6d4c5-9zgrs -n debug-lab
```

5. Confirmed the application was listening on port 8081.

6. Searched the Helm chart:

```bash
grep -R "8080" .
```

7. Identified `common.port` in `broken-chart/values.yaml` as the incorrect configuration source.

---

## Defect 2

**Symptom:**

After fixing the application port configuration, verification improved significantly:

```
./scenario.sh verify

PASS  migrate Job completed
PASS  deployment backend: 1/1 ready
PASS  deployment gateway: 1/1 ready
PASS  deployment worker: 1/1 ready
FAIL  deployment reporter: 0/1 ready
PASS  deployment metrics: 1/1 ready
PASS  no pods in CrashLoopBackOff
PASS  ServiceAccount debug-lab/reporter can list pods
PASS  backend answers on http://backend:8080/healthz
PASS  gateway /status reports backend=ok
FAIL  reporter /report does not return a pod count
```

**Cause:**

The reporter application was running but failed its readiness check because it could not successfully retrieve the Kubernetes pod list.

Reporter logs showed:

```
pod list failed: parse pod list: unexpected end of JSON input
GET /healthz -> 503
```

The reporter application was unable to process the pod list response from the Kubernetes API.

**Fix** (what you changed, and why this over alternatives):

The issue was not resolved within the available investigation time.

The next investigation step would be validating the Kubernetes API response from inside the reporter container and reviewing the Role and RoleBinding configuration.

**How I found it:**

1. Checked remaining verification failures:

```bash
./scenario.sh verify
```

2. Located the failing reporter pods:

```bash
kubectl get pods -n debug-lab | grep reporter
```

3. Inspected reporter pod events:

```bash
kubectl describe pod reporter-6fb7c8dcd9-xg6nf -n debug-lab
```

4. Found readiness failure:

```
Readiness probe failed: HTTP probe failed with statuscode: 503
```

5. Checked reporter logs:

```bash
kubectl logs reporter-6fb7c8dcd9-xg6nf -n debug-lab
```

6. Identified the application error:

```
pod list failed: parse pod list: unexpected end of JSON input
```

---

## Defect 3

No additional defect identified within the available investigation time.

---

## Defect 4

No additional defect identified within the available investigation time.

---

## Defect 5

No additional defect identified within the available investigation time.

---

## Defect 6

No additional defect identified within the available investigation time.

---

## Remaining Investigation

The remaining reporter issue would be investigated by:

1. Testing Kubernetes API access from inside the reporter pod.
2. Validating the ServiceAccount token and API response.
3. Reviewing Role and RoleBinding permissions.
4. Checking whether the reporter application expects additional environment configuration.
