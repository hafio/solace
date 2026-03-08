# Solace-IBMMQ Connector Deployment Guide (Kubernetes)

As the required jar libraries are not distributed inside the container image, this guide will explain how to use Persistent Volume Claim (PVC) to make the jar libraries available for the pods.

## Prerequisites

* **Storage Class**: A StorageClass that supports `ReadWriteMany` (RWX) is required if you plan to scale the connector across multiple nodes.

> [!IMPORTANT]
> If ReadMany storage class is not available, you would need to create multiple ReadOnce PVCs and use it for every pod running the connector.

## How it works:

1. Create a PVC
2. 
   1. Method 1: Utilize a Job to download the jar libraries, or
   2. Method 2: Copy the files manually into the pod with the mounted PVC
3. Add PVC mount to connector yaml

## Steps:

> [!NOTE]
> Full deployment yaml for Method 1: [lib-downloader.yaml](lib-downloader.yaml) <br>
> Full deployment yaml for Method 2: [lib-copy-helper.yaml](lib-copy-helper.yaml) 

### 1. Create PVC

`kubectl` the following yaml:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: solace-ibmmq-connector-library-pvc
  namespace: solace-ibmmq-connector-ns
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: <Storage Class Name>
  resources:
    requests:
      storage: 100Mi # adjust storage size accordingly
```

### 2. Method 1: Utilize job to download jar libraries

`kubectl` the following yaml:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: lib-downloader-script
  namespace: solace-ibmmq-connector-ns
data:
  download.sh: |-
    #!/bin/bash
    # Target directory for JARs (matches your volume mount path)
    LIB_DIR="/app/external/libs"
    # Create directory if it doesn't exist
    mkdir -p "$LIB_DIR"
    # Array of JAR download URLs from Maven Central
    # Note: Use repo1.maven.org for direct file access
    
    # Add/Change/Remove URLs:
    JAR_URLS=(
        "https://repo1.maven.org/maven2/com/ibm/mq/com.ibm.mq.allclient/9.3.4.0/com.ibm.mq.allclient-9.3.4.0.jar"
        "https://repo1.maven.org/maven2/javax/jms/javax.jms-api/2.0.1/javax.jms-api-2.0.1.jar"
        "https://repo1.maven.org/maven2/org/json/json/20231013/json-20231013.jar"
    )
    echo "Starting library synchronization to $LIB_DIR..."
    for url in "${JAR_URLS[@]}"; do
        # Extract filename from URL
        file_name=$(basename "$url")
        
        # Check if file already exists to avoid redundant downloads
        if [ -f "$LIB_DIR/$file_name" ]; then
            echo "[SKIP] $file_name already exists."
        else
            echo "[DOWNLOAD] Fetching $file_name..."
            # -q for quiet, -nc to not overwrite, -P for prefix directory
            wget -q -nc -P "$LIB_DIR" "$url"
            
            if [ $? -eq 0 ]; then
                echo "[SUCCESS] Saved $file_name"
            else
                echo "[ERROR] Failed to download $file_name"
                exit 1
            fi
        fi
    done
    echo "Synchronization complete. Listing contents of $LIB_DIR:"
    chmod -R 644 "$LIB_DIR"/*.jar
    ls -lh "$LIB_DIR"
---
apiVersion: batch/v1
kind: Job
metadata:
  name: solace-mq-lib-populator
  namespace: solace-ibmmq-connector-ns
spec:
  template:
    spec:
      containers:
      - name: downloader
        image: bash:latest
        command: ["/bin/bash", "/download.sh"]
        volumeMounts:
        - name: jar-libraries
          mountPath: /app/external/libs
        - name: download-script
          mountPath: /download.sh
          subPath: download.sh
          readOnly: true
      restartPolicy: OnFailure
      volumes:
      - name: jar-libraries
        persistentVolumeClaim:
          claimName: solace-ibmmq-connector-library-pvc
      - name: download-script
        configMap:
          name: lib-downloader-script
          defaultMode: 0755
```

### 2. Method 2: Copy files manually into pod

`kubectl` the following yaml:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: solace-mq-lib-helper
  namespace: solace-ibmmq-connector-ns
spec:
  template:
    spec:
      containers:
      - name: helper
        image: busybox:latest
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: jar-libraries
          mountPath: /app/external/libs
      volumes:
      - name: jar-libraries
        persistentVolumeClaim:
          claimName: solace-ibmmq-connector-library-pvc
```

Execute `kubectl cp <jar file> solace-mq-lib-helper:/app/external/libs/<jar file>` or `kubectl cp <jar folder>/ solace-mq-lib-helper:/app/external/libs/`

And verify via `kubectl exec solace-mq-lib-helper -- ls -lah /app/external/libs`

### 3. Mount PVC to Pod

Ensure the following is in the Pod yaml:

```yaml
spec:
  template:
    spec:
      containers:
        volumeMounts:
        - name: jar-libraries
          mountPath: /app/external/libs
          readOnly: true
      volumes:
      - name: jar-libraries
        persistentVolumeClaim:
          claimName: solace-ibmmq-connector-library-pvc
```

## Troubleshooting

* **Permission Denied**: If the Java application cannot read the JARs, ensure the `securityContext.fsGroup` matches the User ID of the container (typically `1000` for PSA images).
* **Storage Class**: If the PVC remains in `Pending` state, check `kubectl describe pvc` to ensure the `storageClassName` is supported by your cluster.