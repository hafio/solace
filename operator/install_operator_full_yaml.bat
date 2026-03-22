@echo off

set kube=kubectl.exe

set operator_image=docker.io/solace/pubsubplus-eventbroker-operator:1.2.0
set watch_namespace=solace,solace-pubsubplus,sol-pubsubplus,pubsubplus
set op_tmp_yaml=.operator.yaml

set op_limits_cpu=500m
set op_limits_mem=512Mi


(
echo apiVersion: v1
echo kind: Namespace
echo metadata:
echo   labels:
echo     control-plane: controller-manager
echo   name: pubsubplus-operator-system
echo ---
echo apiVersion: apiextensions.k8s.io/v1
echo kind: CustomResourceDefinition
echo metadata:
echo   annotations:
echo     controller-gen.kubebuilder.io/version: v0.14.0
echo   name: pubsubpluseventbrokers.pubsubplus.solace.com
echo spec:
echo   group: pubsubplus.solace.com
echo   names:
echo     kind: PubSubPlusEventBroker
echo     listKind: PubSubPlusEventBrokerList
echo     plural: pubsubpluseventbrokers
echo     shortNames:
echo     - eb
echo     - eventbroker
echo     singular: pubsubpluseventbroker
echo   scope: Namespaced
echo   versions:
echo   - name: v1beta1
echo     schema:
echo       openAPIV3Schema:
echo         description: PubSub+ Event Broker
echo         properties:
echo           apiVersion:
echo             description: ^|-
echo               APIVersion defines the versioned schema of this representation of an object.
echo               Servers should convert recognized schemas to the latest internal value, and
echo               may reject unrecognized values.
echo               More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
echo             type: string
echo           kind:
echo             description: ^|-
echo               Kind is a string value representing the REST resource this object represents.
echo               Servers may infer this from the endpoint the client submits requests to.
echo               Cannot be updated.
echo               In CamelCase.
echo               More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
echo             type: string
echo           metadata:
echo             type: object
echo           spec:
echo             description: EventBrokerSpec defines the desired state of PubSubPlusEventBroker
echo             properties:
echo               adminCredentialsSecret:
echo                 description: ^|-
echo                   Defines the password for PubSubPlusEventBroker if provided. Random one will be generated if not provided.
echo                   When provided, ensure the secret key name is `username_admin_password`. For valid values refer to the Solace documentation https://docs.solace.com/Admin/Configuring-Internal-CLI-User-Accounts.htm.
echo                 nullable: true
echo                 type: string
echo               brokerContainerSecurity:
echo                 description: ContainerSecurityContext defines the container security
echo                   context for the PubSubPlusEventBroker.
echo                 properties:
echo                   runAsGroup:
echo                     description: Specifies runAsGroup in container security context.
echo                       0 or unset defaults either to 1000002, or if OpenShift detected
echo                       to unspecified (see documentation^)
echo                     format: int64
echo                     type: number
echo                   runAsUser:
echo                     description: Specifies runAsUser in container security context.
echo                       0 or unset defaults either to 1000001, or if OpenShift detected
echo                       to unspecified (see documentation^)
echo                     format: int64
echo                     type: number
echo                 type: object
echo               developer:
echo                 default: false
echo                 description: ^|-
echo                   Developer true specifies a minimum footprint scaled-down deployment, not for production use.
echo                   If set to true it overrides SystemScaling parameters.
echo                 type: boolean
echo               enableServiceLinks:
echo                 default: false
echo                 description: ^|-
echo                   EnableServiceLinks indicates whether information about services should be injected into pod's environment
echo                   variables, matching the syntax of Docker links. Optional: Defaults to false.
echo                 type: boolean
echo               extraEnvVars:
echo                 description: ^|-
echo                   List of extra environment variables to be added to the PubSubPlusEventBroker container. Note: Do not configure Timezone or SystemScaling parameters here as it could cause unintended consequences.
echo                   A primary use case is to specify configuration keys, although the variables defined here will not override the ones defined in ConfigMap
echo                 items:
echo                   description: ExtraEnvVar defines environment variables to be added
echo                     to the PubSubPlusEventBroker container
echo                   properties:
echo                     name:
echo                       description: Specifies the Name of an environment variable to
echo                         be added to the PubSubPlusEventBroker container
echo                       type: string
echo                     value:
echo                       description: Specifies the Value of an environment variable
echo                         to be added to the PubSubPlusEventBroker container
echo                       type: string
echo                   required:
echo                   - name
echo                   - value
echo                   type: object
echo                 type: array
echo               extraEnvVarsCM:
echo                 description: 'List of extra environment variables to be added to the
echo                   PubSubPlusEventBroker container from an existing ConfigMap. Note:
echo                   Do not configure Timezone or SystemScaling parameters here as it
echo                   could cause unintended consequences.'
echo                 type: string
echo               extraEnvVarsSecret:
echo                 description: List of extra environment variables to be added to the
echo                   PubSubPlusEventBroker container from an existing Secret
echo                 type: string
echo               image:
echo                 description: Image defines container image parameters for the event
echo                   broker.
echo                 properties:
echo                   pullPolicy:
echo                     default: IfNotPresent
echo                     description: Specifies ImagePullPolicy of the container image
echo                       for the event broker.
echo                     type: string
echo                   pullSecrets:
echo                     description: pullSecrets is an optional list of references to
echo                       secrets in the same namespace to use for pulling any of the
echo                       images used by this PodSpec.
echo                     items:
echo                       description: ^|-
echo                         LocalObjectReference contains enough information to let you locate the
echo                         referenced object inside the same namespace.
echo                       properties:
echo                         name:
echo                           description: ^|-
echo                             Name of the referent.
echo                             More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
echo                             TODO: Add other useful fields. apiVersion, kind, uid?
echo                           type: string
echo                       type: object
echo                       x-kubernetes-map-type: atomic
echo                     type: array
echo                   repository:
echo                     description: Defines the container image repo where the event
echo                       broker image is pulled from
echo                     type: string
echo                   tag:
echo                     default: latest
echo                     description: Specifies the tag of the container image to be used
echo                       for the event broker.
echo                     type: string
echo                 type: object
echo               monitoring:
echo                 description: Monitoring specifies a Prometheus monitoring endpoint
echo                   for the event broker
echo                 properties:
echo                   enabled:
echo                     default: false
echo                     description: Enabled true enables the setup of the Prometheus
echo                       Exporter.
echo                     type: boolean
echo                   extraEnvVars:
echo                     description: List of extra environment variables to be added to
echo                       the Prometheus Exporter container.
echo                     items:
echo                       description: MonitoringExtraEnvVar defines environment variables
echo                         to be added to the Prometheus Exporter container for Monitoring
echo                       properties:
echo                         name:
echo                           description: Specifies the Name of an environment variable
echo                             to be added to the Prometheus Exporter container for Monitoring
echo                           type: string
echo                         value:
echo                           description: Specifies the Value of an environment variable
echo                             to be added to the Prometheus Exporter container for Monitoring
echo                           type: string
echo                       required:
echo                       - name
echo                       - value
echo                       type: object
echo                     type: array
echo                   image:
echo                     description: Image defines container image parameters for the
echo                       Prometheus Exporter.
echo                     properties:
echo                       pullPolicy:
echo                         default: IfNotPresent
echo                         description: Specifies ImagePullPolicy of the container image
echo                           for the Prometheus Exporter.
echo                         type: string
echo                       pullSecrets:
echo                         description: pullSecrets is an optional list of references
echo                           to secrets in the same namespace to use for pulling any
echo                           of the images used by this PodSpec.
echo                         items:
echo                           description: ^|-
echo                             LocalObjectReference contains enough information to let you locate the
echo                             referenced object inside the same namespace.
echo                           properties:
echo                             name:
echo                               description: ^|-
echo                                 Name of the referent.
echo                                 More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
echo                                 TODO: Add other useful fields. apiVersion, kind, uid?
echo                               type: string
echo                           type: object
echo                           x-kubernetes-map-type: atomic
echo                         type: array
echo                       repository:
echo                         description: Defines the container image repo where the Prometheus
echo                           Exporter image is pulled from
echo                         type: string
echo                       tag:
echo                         default: latest
echo                         description: Specifies the tag of the container image to be
echo                           used for the Prometheus Exporter.
echo                         type: string
echo                     type: object
echo                   includeRates:
echo                     default: false
echo                     description: Defines if Prometheus Exporter should include rates
echo                     type: boolean
echo                   metricsEndpoint:
echo                     description: MetricsEndpoint defines parameters to configure monitoring
echo                       for the Prometheus Exporter.
echo                     properties:
echo                       containerPort:
echo                         default: 9628
echo                         description: ContainerPort is the port number to expose on
echo                           the Prometheus Exporter pod.
echo                         format: int32
echo                         type: number
echo                       endpointTlsConfigPrivateKeyName:
echo                         default: tls.key
echo                         description: EndpointTlsConfigPrivateKeyName is the file name
echo                           of the Private Key used to set up TLS configuration
echo                         type: string
echo                       endpointTlsConfigSecret:
echo                         description: EndpointTLSConfigSecret defines TLS secret name
echo                           to set up TLS configuration
echo                         type: string
echo                       endpointTlsConfigServerCertName:
echo                         default: tls.crt
echo                         description: EndpointTlsConfigServerCertName is the file name
echo                           of the Server Certificate used to set up TLS configuration
echo                         type: string
echo                       listenTLS:
echo                         default: false
echo                         description: Defines if Metrics Service Endpoint uses TLS
echo                           configuration
echo                         type: boolean
echo                       name:
echo                         description: Name is a unique name for the port that can be
echo                           referred to by services.
echo                         type: string
echo                       protocol:
echo                         default: TCP
echo                         description: Protocol for port. Must be UDP, TCP, or SCTP.
echo                         enum:
echo                         - TCP
echo                         - UDP
echo                         - SCTP
echo                         type: string
echo                       servicePort:
echo                         default: 9628
echo                         description: ServicePort is the port number to expose on the
echo                           service
echo                         format: int32
echo                         type: number
echo                       serviceType:
echo                         default: ClusterIP
echo                         description: Defines the service type for the Metrics Service
echo                           Endpoint
echo                         type: string
echo                     type: object
echo                   sslVerify:
echo                     default: false
echo                     description: Defines if Prometheus Exporter verifies SSL
echo                     type: boolean
echo                   timeOut:
echo                     default: 5
echo                     description: Timeout configuration for Prometheus Exporter scrapper
echo                     format: int32
echo                     type: number
echo                 type: object
echo               monitoringCredentialsSecret:
echo                 description: ^|-
echo                   Defines the password for PubSubPlusEventBroker to be used by the Exporter for monitoring.
echo                   When provided, ensure the secret key name is `username_monitor_password`. For valid values refer to the Solace documentation https://docs.solace.com/Admin/Configuring-Internal-CLI-User-Accounts.htm.
echo                 nullable: true
echo                 type: string
echo               nodeAssignment:
echo                 description: NodeAssignment defines labels to constrain PubSubPlusEventBroker
echo                   nodes to run on particular node(s^), or to prefer to run on particular
echo                   nodes.
echo                 items:
echo                   description: NodeAssignment defines labels to constrain PubSubPlusEventBroker
echo                     nodes to specific nodes
echo                   properties:
echo                     name:
echo                       description: Defines the name of broker node type that has the
echo                         nodeAssignment spec defined
echo                       enum:
echo                       - Primary
echo                       - Backup
echo                       - Monitor
echo                       type: string
echo                     spec:
echo                       description: If provided defines the labels to constrain the
echo                         PubSubPlusEventBroker node to specific nodes
echo                       properties:
echo                         affinity:
echo                           default: {}
echo                           description: Affinity if provided defines the conditional
echo                             approach to assign PubSubPlusEventBroker nodes to specific
echo                             nodes to which they can be scheduled
echo                           nullable: true
echo                           properties:
echo                             nodeAffinity:
echo                               description: Describes node affinity scheduling rules
echo                                 for the pod.
echo                               properties:
echo                                 preferredDuringSchedulingIgnoredDuringExecution:
echo                                   description: ^|-
echo                                     The scheduler will prefer to schedule pods to nodes that satisfy
echo                                     the affinity expressions specified by this field, but it may choose
echo                                     a node that violates one or more of the expressions. The node that is
echo                                     most preferred is the one with the greatest sum of weights, i.e.
echo                                     for each node that meets all of the scheduling requirements (resource
echo                                     request, requiredDuringScheduling affinity expressions, etc.^),
echo                                     compute a sum by iterating through the elements of this field and adding
echo                                     "weight" to the sum if the node matches the corresponding matchExpressions; the
echo                                     node(s^) with the highest sum are the most preferred.
echo                                   items:
echo                                     description: ^|-
echo                                       An empty preferred scheduling term matches all objects with implicit weight 0
echo                                       (i.e. it's a no-op^). A null preferred scheduling term matches no objects (i.e. is also a no-op^).
echo                                     properties:
echo                                       preference:
echo                                         description: A node selector term, associated
echo                                           with the corresponding weight.
echo                                         properties:
echo                                           matchExpressions:
echo                                             description: A list of node selector requirements
echo                                               by node's labels.
echo                                             items:
echo                                               description: ^|-
echo                                                 A node selector requirement is a selector that contains values, a key, and an operator
echo                                                 that relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: The label key that
echo                                                     the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     Represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     An array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. If the operator is Gt or Lt, the values
echo                                                     array must have a single element, which will be interpreted as an integer.
echo                                                     This array is replaced during a strategic merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                           matchFields:
echo                                             description: A list of node selector requirements
echo                                               by node's fields.
echo                                             items:
echo                                               description: ^|-
echo                                                 A node selector requirement is a selector that contains values, a key, and an operator
echo                                                 that relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: The label key that
echo                                                     the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     Represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     An array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. If the operator is Gt or Lt, the values
echo                                                     array must have a single element, which will be interpreted as an integer.
echo                                                     This array is replaced during a strategic merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                         type: object
echo                                         x-kubernetes-map-type: atomic
echo                                       weight:
echo                                         description: Weight associated with matching
echo                                           the corresponding nodeSelectorTerm, in the
echo                                           range 1-100.
echo                                         format: int32
echo                                         type: integer
echo                                     required:
echo                                     - preference
echo                                     - weight
echo                                     type: object
echo                                   type: array
echo                                 requiredDuringSchedulingIgnoredDuringExecution:
echo                                   description: ^|-
echo                                     If the affinity requirements specified by this field are not met at
echo                                     scheduling time, the pod will not be scheduled onto the node.
echo                                     If the affinity requirements specified by this field cease to be met
echo                                     at some point during pod execution (e.g. due to an update^), the system
echo                                     may or may not try to eventually evict the pod from its node.
echo                                   properties:
echo                                     nodeSelectorTerms:
echo                                       description: Required. A list of node selector
echo                                         terms. The terms are ORed.
echo                                       items:
echo                                         description: ^|-
echo                                           A null or empty node selector term matches no objects. The requirements of
echo                                           them are ANDed.
echo                                           The TopologySelectorTerm type implements a subset of the NodeSelectorTerm.
echo                                         properties:
echo                                           matchExpressions:
echo                                             description: A list of node selector requirements
echo                                               by node's labels.
echo                                             items:
echo                                               description: ^|-
echo                                                 A node selector requirement is a selector that contains values, a key, and an operator
echo                                                 that relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: The label key that
echo                                                     the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     Represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     An array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. If the operator is Gt or Lt, the values
echo                                                     array must have a single element, which will be interpreted as an integer.
echo                                                     This array is replaced during a strategic merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                           matchFields:
echo                                             description: A list of node selector requirements
echo                                               by node's fields.
echo                                             items:
echo                                               description: ^|-
echo                                                 A node selector requirement is a selector that contains values, a key, and an operator
echo                                                 that relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: The label key that
echo                                                     the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     Represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     An array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. If the operator is Gt or Lt, the values
echo                                                     array must have a single element, which will be interpreted as an integer.
echo                                                     This array is replaced during a strategic merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                         type: object
echo                                         x-kubernetes-map-type: atomic
echo                                       type: array
echo                                   required:
echo                                   - nodeSelectorTerms
echo                                   type: object
echo                                   x-kubernetes-map-type: atomic
echo                               type: object
echo                             podAffinity:
echo                               description: Describes pod affinity scheduling rules
echo                                 (e.g. co-locate this pod in the same node, zone, etc.
echo                                 as some other pod(s^)^).
echo                               properties:
echo                                 preferredDuringSchedulingIgnoredDuringExecution:
echo                                   description: ^|-
echo                                     The scheduler will prefer to schedule pods to nodes that satisfy
echo                                     the affinity expressions specified by this field, but it may choose
echo                                     a node that violates one or more of the expressions. The node that is
echo                                     most preferred is the one with the greatest sum of weights, i.e.
echo                                     for each node that meets all of the scheduling requirements (resource
echo                                     request, requiredDuringScheduling affinity expressions, etc.^),
echo                                     compute a sum by iterating through the elements of this field and adding
echo                                     "weight" to the sum if the node has pods which matches the corresponding podAffinityTerm; the
echo                                     node(s^) with the highest sum are the most preferred.
echo                                   items:
echo                                     description: The weights of all of the matched
echo                                       WeightedPodAffinityTerm fields are added per-node
echo                                       to find the most preferred node(s^)
echo                                     properties:
echo                                       podAffinityTerm:
echo                                         description: Required. A pod affinity term,
echo                                           associated with the corresponding weight.
echo                                         properties:
echo                                           labelSelector:
echo                                             description: ^|-
echo                                               A label query over a set of resources, in this case pods.
echo                                               If it's null, this PodAffinityTerm matches with no Pods.
echo                                             properties:
echo                                               matchExpressions:
echo                                                 description: matchExpressions is a
echo                                                   list of label selector requirements.
echo                                                   The requirements are ANDed.
echo                                                 items:
echo                                                   description: ^|-
echo                                                     A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                     relates the key and values.
echo                                                   properties:
echo                                                     key:
echo                                                       description: key is the label
echo                                                         key that the selector applies
echo                                                         to.
echo                                                       type: string
echo                                                     operator:
echo                                                       description: ^|-
echo                                                         operator represents a key's relationship to a set of values.
echo                                                         Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                       type: string
echo                                                     values:
echo                                                       description: ^|-
echo                                                         values is an array of string values. If the operator is In or NotIn,
echo                                                         the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                         the values array must be empty. This array is replaced during a strategic
echo                                                         merge patch.
echo                                                       items:
echo                                                         type: string
echo                                                       type: array
echo                                                   required:
echo                                                   - key
echo                                                   - operator
echo                                                   type: object
echo                                                 type: array
echo                                               matchLabels:
echo                                                 additionalProperties:
echo                                                   type: string
echo                                                 description: ^|-
echo                                                   matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                                   map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                                   operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                                 type: object
echo                                             type: object
echo                                             x-kubernetes-map-type: atomic
echo                                           matchLabelKeys:
echo                                             description: ^|-
echo                                               MatchLabelKeys is a set of pod label keys to select which pods will
echo                                               be taken into consideration. The keys are used to lookup values from the
echo                                               incoming pod labels, those key-value labels are merged with `LabelSelector` as `key in (value^)`
echo                                               to select the group of existing pods which pods will be taken into consideration
echo                                               for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                               pod labels will be ignored. The default value is empty.
echo                                               The same key is forbidden to exist in both MatchLabelKeys and LabelSelector.
echo                                               Also, MatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                               This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                             items:
echo                                               type: string
echo                                             type: array
echo                                             x-kubernetes-list-type: atomic
echo                                           mismatchLabelKeys:
echo                                             description: ^|-
echo                                               MismatchLabelKeys is a set of pod label keys to select which pods will
echo                                               be taken into consideration. The keys are used to lookup values from the
echo                                               incoming pod labels, those key-value labels are merged with `LabelSelector` as `key notin (value^)`
echo                                               to select the group of existing pods which pods will be taken into consideration
echo                                               for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                               pod labels will be ignored. The default value is empty.
echo                                               The same key is forbidden to exist in both MismatchLabelKeys and LabelSelector.
echo                                               Also, MismatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                               This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                             items:
echo                                               type: string
echo                                             type: array
echo                                             x-kubernetes-list-type: atomic
echo                                           namespaceSelector:
echo                                             description: ^|-
echo                                               A label query over the set of namespaces that the term applies to.
echo                                               The term is applied to the union of the namespaces selected by this field
echo                                               and the ones listed in the namespaces field.
echo                                               null selector and null or empty namespaces list means "this pod's namespace".
echo                                               An empty selector ({}^) matches all namespaces.
echo                                             properties:
echo                                               matchExpressions:
echo                                                 description: matchExpressions is a
echo                                                   list of label selector requirements.
echo                                                   The requirements are ANDed.
echo                                                 items:
echo                                                   description: ^|-
echo                                                     A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                     relates the key and values.
echo                                                   properties:
echo                                                     key:
echo                                                       description: key is the label
echo                                                         key that the selector applies
echo                                                         to.
echo                                                       type: string
echo                                                     operator:
echo                                                       description: ^|-
echo                                                         operator represents a key's relationship to a set of values.
echo                                                         Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                       type: string
echo                                                     values:
echo                                                       description: ^|-
echo                                                         values is an array of string values. If the operator is In or NotIn,
echo                                                         the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                         the values array must be empty. This array is replaced during a strategic
echo                                                         merge patch.
echo                                                       items:
echo                                                         type: string
echo                                                       type: array
echo                                                   required:
echo                                                   - key
echo                                                   - operator
echo                                                   type: object
echo                                                 type: array
echo                                               matchLabels:
echo                                                 additionalProperties:
echo                                                   type: string
echo                                                 description: ^|-
echo                                                   matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                                   map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                                   operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                                 type: object
echo                                             type: object
echo                                             x-kubernetes-map-type: atomic
echo                                           namespaces:
echo                                             description: ^|-
echo                                               namespaces specifies a static list of namespace names that the term applies to.
echo                                               The term is applied to the union of the namespaces listed in this field
echo                                               and the ones selected by namespaceSelector.
echo                                               null or empty namespaces list and null namespaceSelector means "this pod's namespace".
echo                                             items:
echo                                               type: string
echo                                             type: array
echo                                           topologyKey:
echo                                             description: ^|-
echo                                               This pod should be co-located (affinity^) or not co-located (anti-affinity^) with the pods matching
echo                                               the labelSelector in the specified namespaces, where co-located is defined as running on a node
echo                                               whose value of the label with key topologyKey matches that of any node on which any of the
echo                                               selected pods is running.
echo                                               Empty topologyKey is not allowed.
echo                                             type: string
echo                                         required:
echo                                         - topologyKey
echo                                         type: object
echo                                       weight:
echo                                         description: ^|-
echo                                           weight associated with matching the corresponding podAffinityTerm,
echo                                           in the range 1-100.
echo                                         format: int32
echo                                         type: integer
echo                                     required:
echo                                     - podAffinityTerm
echo                                     - weight
echo                                     type: object
echo                                   type: array
echo                                 requiredDuringSchedulingIgnoredDuringExecution:
echo                                   description: ^|-
echo                                     If the affinity requirements specified by this field are not met at
echo                                     scheduling time, the pod will not be scheduled onto the node.
echo                                     If the affinity requirements specified by this field cease to be met
echo                                     at some point during pod execution (e.g. due to a pod label update^), the
echo                                     system may or may not try to eventually evict the pod from its node.
echo                                     When there are multiple elements, the lists of nodes corresponding to each
echo                                     podAffinityTerm are intersected, i.e. all terms must be satisfied.
echo                                   items:
echo                                     description: ^|-
echo                                       Defines a set of pods (namely those matching the labelSelector
echo                                       relative to the given namespace(s^)^) that this pod should be
echo                                       co-located (affinity^) or not co-located (anti-affinity^) with,
echo                                       where co-located is defined as running on a node whose value of
echo                                       the label with key ^<topologyKey^> matches that of any node on which
echo                                       a pod of the set of pods is running
echo                                     properties:
echo                                       labelSelector:
echo                                         description: ^|-
echo                                           A label query over a set of resources, in this case pods.
echo                                           If it's null, this PodAffinityTerm matches with no Pods.
echo                                         properties:
echo                                           matchExpressions:
echo                                             description: matchExpressions is a list
echo                                               of label selector requirements. The
echo                                               requirements are ANDed.
echo                                             items:
echo                                               description: ^|-
echo                                                 A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                 relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: key is the label key
echo                                                     that the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     operator represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     values is an array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. This array is replaced during a strategic
echo                                                     merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                           matchLabels:
echo                                             additionalProperties:
echo                                               type: string
echo                                             description: ^|-
echo                                               matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                               map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                               operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                             type: object
echo                                         type: object
echo                                         x-kubernetes-map-type: atomic
echo                                       matchLabelKeys:
echo                                         description: ^|-
echo                                           MatchLabelKeys is a set of pod label keys to select which pods will
echo                                           be taken into consideration. The keys are used to lookup values from the
echo                                           incoming pod labels, those key-value labels are merged with `LabelSelector` as `key in (value^)`
echo                                           to select the group of existing pods which pods will be taken into consideration
echo                                           for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                           pod labels will be ignored. The default value is empty.
echo                                           The same key is forbidden to exist in both MatchLabelKeys and LabelSelector.
echo                                           Also, MatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                           This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                         items:
echo                                           type: string
echo                                         type: array
echo                                         x-kubernetes-list-type: atomic
echo                                       mismatchLabelKeys:
echo                                         description: ^|-
echo                                           MismatchLabelKeys is a set of pod label keys to select which pods will
echo                                           be taken into consideration. The keys are used to lookup values from the
echo                                           incoming pod labels, those key-value labels are merged with `LabelSelector` as `key notin (value^)`
echo                                           to select the group of existing pods which pods will be taken into consideration
echo                                           for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                           pod labels will be ignored. The default value is empty.
echo                                           The same key is forbidden to exist in both MismatchLabelKeys and LabelSelector.
echo                                           Also, MismatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                           This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                         items:
echo                                           type: string
echo                                         type: array
echo                                         x-kubernetes-list-type: atomic
echo                                       namespaceSelector:
echo                                         description: ^|-
echo                                           A label query over the set of namespaces that the term applies to.
echo                                           The term is applied to the union of the namespaces selected by this field
echo                                           and the ones listed in the namespaces field.
echo                                           null selector and null or empty namespaces list means "this pod's namespace".
echo                                           An empty selector ({}^) matches all namespaces.
echo                                         properties:
echo                                           matchExpressions:
echo                                             description: matchExpressions is a list
echo                                               of label selector requirements. The
echo                                               requirements are ANDed.
echo                                             items:
echo                                               description: ^|-
echo                                                 A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                 relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: key is the label key
echo                                                     that the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     operator represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     values is an array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. This array is replaced during a strategic
echo                                                     merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                           matchLabels:
echo                                             additionalProperties:
echo                                               type: string
echo                                             description: ^|-
echo                                               matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                               map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                               operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                             type: object
echo                                         type: object
echo                                         x-kubernetes-map-type: atomic
echo                                       namespaces:
echo                                         description: ^|-
echo                                           namespaces specifies a static list of namespace names that the term applies to.
echo                                           The term is applied to the union of the namespaces listed in this field
echo                                           and the ones selected by namespaceSelector.
echo                                           null or empty namespaces list and null namespaceSelector means "this pod's namespace".
echo                                         items:
echo                                           type: string
echo                                         type: array
echo                                       topologyKey:
echo                                         description: ^|-
echo                                           This pod should be co-located (affinity^) or not co-located (anti-affinity^) with the pods matching
echo                                           the labelSelector in the specified namespaces, where co-located is defined as running on a node
echo                                           whose value of the label with key topologyKey matches that of any node on which any of the
echo                                           selected pods is running.
echo                                           Empty topologyKey is not allowed.
echo                                         type: string
echo                                     required:
echo                                     - topologyKey
echo                                     type: object
echo                                   type: array
echo                               type: object
echo                             podAntiAffinity:
echo                               description: Describes pod anti-affinity scheduling
echo                                 rules (e.g. avoid putting this pod in the same node,
echo                                 zone, etc. as some other pod(s^)^).
echo                               properties:
echo                                 preferredDuringSchedulingIgnoredDuringExecution:
echo                                   description: ^|-
echo                                     The scheduler will prefer to schedule pods to nodes that satisfy
echo                                     the anti-affinity expressions specified by this field, but it may choose
echo                                     a node that violates one or more of the expressions. The node that is
echo                                     most preferred is the one with the greatest sum of weights, i.e.
echo                                     for each node that meets all of the scheduling requirements (resource
echo                                     request, requiredDuringScheduling anti-affinity expressions, etc.^),
echo                                     compute a sum by iterating through the elements of this field and adding
echo                                     "weight" to the sum if the node has pods which matches the corresponding podAffinityTerm; the
echo                                     node(s^) with the highest sum are the most preferred.
echo                                   items:
echo                                     description: The weights of all of the matched
echo                                       WeightedPodAffinityTerm fields are added per-node
echo                                       to find the most preferred node(s^)
echo                                     properties:
echo                                       podAffinityTerm:
echo                                         description: Required. A pod affinity term,
echo                                           associated with the corresponding weight.
echo                                         properties:
echo                                           labelSelector:
echo                                             description: ^|-
echo                                               A label query over a set of resources, in this case pods.
echo                                               If it's null, this PodAffinityTerm matches with no Pods.
echo                                             properties:
echo                                               matchExpressions:
echo                                                 description: matchExpressions is a
echo                                                   list of label selector requirements.
echo                                                   The requirements are ANDed.
echo                                                 items:
echo                                                   description: ^|-
echo                                                     A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                     relates the key and values.
echo                                                   properties:
echo                                                     key:
echo                                                       description: key is the label
echo                                                         key that the selector applies
echo                                                         to.
echo                                                       type: string
echo                                                     operator:
echo                                                       description: ^|-
echo                                                         operator represents a key's relationship to a set of values.
echo                                                         Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                       type: string
echo                                                     values:
echo                                                       description: ^|-
echo                                                         values is an array of string values. If the operator is In or NotIn,
echo                                                         the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                         the values array must be empty. This array is replaced during a strategic
echo                                                         merge patch.
echo                                                       items:
echo                                                         type: string
echo                                                       type: array
echo                                                   required:
echo                                                   - key
echo                                                   - operator
echo                                                   type: object
echo                                                 type: array
echo                                               matchLabels:
echo                                                 additionalProperties:
echo                                                   type: string
echo                                                 description: ^|-
echo                                                   matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                                   map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                                   operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                                 type: object
echo                                             type: object
echo                                             x-kubernetes-map-type: atomic
echo                                           matchLabelKeys:
echo                                             description: ^|-
echo                                               MatchLabelKeys is a set of pod label keys to select which pods will
echo                                               be taken into consideration. The keys are used to lookup values from the
echo                                               incoming pod labels, those key-value labels are merged with `LabelSelector` as `key in (value^)`
echo                                               to select the group of existing pods which pods will be taken into consideration
echo                                               for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                               pod labels will be ignored. The default value is empty.
echo                                               The same key is forbidden to exist in both MatchLabelKeys and LabelSelector.
echo                                               Also, MatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                               This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                             items:
echo                                               type: string
echo                                             type: array
echo                                             x-kubernetes-list-type: atomic
echo                                           mismatchLabelKeys:
echo                                             description: ^|-
echo                                               MismatchLabelKeys is a set of pod label keys to select which pods will
echo                                               be taken into consideration. The keys are used to lookup values from the
echo                                               incoming pod labels, those key-value labels are merged with `LabelSelector` as `key notin (value^)`
echo                                               to select the group of existing pods which pods will be taken into consideration
echo                                               for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                               pod labels will be ignored. The default value is empty.
echo                                               The same key is forbidden to exist in both MismatchLabelKeys and LabelSelector.
echo                                               Also, MismatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                               This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                             items:
echo                                               type: string
echo                                             type: array
echo                                             x-kubernetes-list-type: atomic
echo                                           namespaceSelector:
echo                                             description: ^|-
echo                                               A label query over the set of namespaces that the term applies to.
echo                                               The term is applied to the union of the namespaces selected by this field
echo                                               and the ones listed in the namespaces field.
echo                                               null selector and null or empty namespaces list means "this pod's namespace".
echo                                               An empty selector ({}^) matches all namespaces.
echo                                             properties:
echo                                               matchExpressions:
echo                                                 description: matchExpressions is a
echo                                                   list of label selector requirements.
echo                                                   The requirements are ANDed.
echo                                                 items:
echo                                                   description: ^|-
echo                                                     A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                     relates the key and values.
echo                                                   properties:
echo                                                     key:
echo                                                       description: key is the label
echo                                                         key that the selector applies
echo                                                         to.
echo                                                       type: string
echo                                                     operator:
echo                                                       description: ^|-
echo                                                         operator represents a key's relationship to a set of values.
echo                                                         Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                       type: string
echo                                                     values:
echo                                                       description: ^|-
echo                                                         values is an array of string values. If the operator is In or NotIn,
echo                                                         the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                         the values array must be empty. This array is replaced during a strategic
echo                                                         merge patch.
echo                                                       items:
echo                                                         type: string
echo                                                       type: array
echo                                                   required:
echo                                                   - key
echo                                                   - operator
echo                                                   type: object
echo                                                 type: array
echo                                               matchLabels:
echo                                                 additionalProperties:
echo                                                   type: string
echo                                                 description: ^|-
echo                                                   matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                                   map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                                   operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                                 type: object
echo                                             type: object
echo                                             x-kubernetes-map-type: atomic
echo                                           namespaces:
echo                                             description: ^|-
echo                                               namespaces specifies a static list of namespace names that the term applies to.
echo                                               The term is applied to the union of the namespaces listed in this field
echo                                               and the ones selected by namespaceSelector.
echo                                               null or empty namespaces list and null namespaceSelector means "this pod's namespace".
echo                                             items:
echo                                               type: string
echo                                             type: array
echo                                           topologyKey:
echo                                             description: ^|-
echo                                               This pod should be co-located (affinity^) or not co-located (anti-affinity^) with the pods matching
echo                                               the labelSelector in the specified namespaces, where co-located is defined as running on a node
echo                                               whose value of the label with key topologyKey matches that of any node on which any of the
echo                                               selected pods is running.
echo                                               Empty topologyKey is not allowed.
echo                                             type: string
echo                                         required:
echo                                         - topologyKey
echo                                         type: object
echo                                       weight:
echo                                         description: ^|-
echo                                           weight associated with matching the corresponding podAffinityTerm,
echo                                           in the range 1-100.
echo                                         format: int32
echo                                         type: integer
echo                                     required:
echo                                     - podAffinityTerm
echo                                     - weight
echo                                     type: object
echo                                   type: array
echo                                 requiredDuringSchedulingIgnoredDuringExecution:
echo                                   description: ^|-
echo                                     If the anti-affinity requirements specified by this field are not met at
echo                                     scheduling time, the pod will not be scheduled onto the node.
echo                                     If the anti-affinity requirements specified by this field cease to be met
echo                                     at some point during pod execution (e.g. due to a pod label update^), the
echo                                     system may or may not try to eventually evict the pod from its node.
echo                                     When there are multiple elements, the lists of nodes corresponding to each
echo                                     podAffinityTerm are intersected, i.e. all terms must be satisfied.
echo                                   items:
echo                                     description: ^|-
echo                                       Defines a set of pods (namely those matching the labelSelector
echo                                       relative to the given namespace(s^)^) that this pod should be
echo                                       co-located (affinity^) or not co-located (anti-affinity^) with,
echo                                       where co-located is defined as running on a node whose value of
echo                                       the label with key ^<topologyKey^> matches that of any node on which
echo                                       a pod of the set of pods is running
echo                                     properties:
echo                                       labelSelector:
echo                                         description: ^|-
echo                                           A label query over a set of resources, in this case pods.
echo                                           If it's null, this PodAffinityTerm matches with no Pods.
echo                                         properties:
echo                                           matchExpressions:
echo                                             description: matchExpressions is a list
echo                                               of label selector requirements. The
echo                                               requirements are ANDed.
echo                                             items:
echo                                               description: ^|-
echo                                                 A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                 relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: key is the label key
echo                                                     that the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     operator represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     values is an array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. This array is replaced during a strategic
echo                                                     merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                           matchLabels:
echo                                             additionalProperties:
echo                                               type: string
echo                                             description: ^|-
echo                                               matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                               map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                               operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                             type: object
echo                                         type: object
echo                                         x-kubernetes-map-type: atomic
echo                                       matchLabelKeys:
echo                                         description: ^|-
echo                                           MatchLabelKeys is a set of pod label keys to select which pods will
echo                                           be taken into consideration. The keys are used to lookup values from the
echo                                           incoming pod labels, those key-value labels are merged with `LabelSelector` as `key in (value^)`
echo                                           to select the group of existing pods which pods will be taken into consideration
echo                                           for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                           pod labels will be ignored. The default value is empty.
echo                                           The same key is forbidden to exist in both MatchLabelKeys and LabelSelector.
echo                                           Also, MatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                           This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                         items:
echo                                           type: string
echo                                         type: array
echo                                         x-kubernetes-list-type: atomic
echo                                       mismatchLabelKeys:
echo                                         description: ^|-
echo                                           MismatchLabelKeys is a set of pod label keys to select which pods will
echo                                           be taken into consideration. The keys are used to lookup values from the
echo                                           incoming pod labels, those key-value labels are merged with `LabelSelector` as `key notin (value^)`
echo                                           to select the group of existing pods which pods will be taken into consideration
echo                                           for the incoming pod's pod (anti^) affinity. Keys that don't exist in the incoming
echo                                           pod labels will be ignored. The default value is empty.
echo                                           The same key is forbidden to exist in both MismatchLabelKeys and LabelSelector.
echo                                           Also, MismatchLabelKeys cannot be set when LabelSelector isn't set.
echo                                           This is an alpha field and requires enabling MatchLabelKeysInPodAffinity feature gate.
echo                                         items:
echo                                           type: string
echo                                         type: array
echo                                         x-kubernetes-list-type: atomic
echo                                       namespaceSelector:
echo                                         description: ^|-
echo                                           A label query over the set of namespaces that the term applies to.
echo                                           The term is applied to the union of the namespaces selected by this field
echo                                           and the ones listed in the namespaces field.
echo                                           null selector and null or empty namespaces list means "this pod's namespace".
echo                                           An empty selector ({}^) matches all namespaces.
echo                                         properties:
echo                                           matchExpressions:
echo                                             description: matchExpressions is a list
echo                                               of label selector requirements. The
echo                                               requirements are ANDed.
echo                                             items:
echo                                               description: ^|-
echo                                                 A label selector requirement is a selector that contains values, a key, and an operator that
echo                                                 relates the key and values.
echo                                               properties:
echo                                                 key:
echo                                                   description: key is the label key
echo                                                     that the selector applies to.
echo                                                   type: string
echo                                                 operator:
echo                                                   description: ^|-
echo                                                     operator represents a key's relationship to a set of values.
echo                                                     Valid operators are In, NotIn, Exists and DoesNotExist.
echo                                                   type: string
echo                                                 values:
echo                                                   description: ^|-
echo                                                     values is an array of string values. If the operator is In or NotIn,
echo                                                     the values array must be non-empty. If the operator is Exists or DoesNotExist,
echo                                                     the values array must be empty. This array is replaced during a strategic
echo                                                     merge patch.
echo                                                   items:
echo                                                     type: string
echo                                                   type: array
echo                                               required:
echo                                               - key
echo                                               - operator
echo                                               type: object
echo                                             type: array
echo                                           matchLabels:
echo                                             additionalProperties:
echo                                               type: string
echo                                             description: ^|-
echo                                               matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels
echo                                               map is equivalent to an element of matchExpressions, whose key field is "key", the
echo                                               operator is "In", and the values array contains only "value". The requirements are ANDed.
echo                                             type: object
echo                                         type: object
echo                                         x-kubernetes-map-type: atomic
echo                                       namespaces:
echo                                         description: ^|-
echo                                           namespaces specifies a static list of namespace names that the term applies to.
echo                                           The term is applied to the union of the namespaces listed in this field
echo                                           and the ones selected by namespaceSelector.
echo                                           null or empty namespaces list and null namespaceSelector means "this pod's namespace".
echo                                         items:
echo                                           type: string
echo                                         type: array
echo                                       topologyKey:
echo                                         description: ^|-
echo                                           This pod should be co-located (affinity^) or not co-located (anti-affinity^) with the pods matching
echo                                           the labelSelector in the specified namespaces, where co-located is defined as running on a node
echo                                           whose value of the label with key topologyKey matches that of any node on which any of the
echo                                           selected pods is running.
echo                                           Empty topologyKey is not allowed.
echo                                         type: string
echo                                     required:
echo                                     - topologyKey
echo                                     type: object
echo                                   type: array
echo                               type: object
echo                           type: object
echo                         nodeSelector:
echo                           additionalProperties:
echo                             type: string
echo                           default: {}
echo                           description: NodeSelector if provided defines the exact
echo                             labels of nodes to which PubSubPlusEventBroker nodes can
echo                             be scheduled
echo                           type: object
echo                         tolerations:
echo                           description: Toleration if provided defines the exact properties
echo                             of the PubSubPlusEventBroker nodes can be scheduled on
echo                             nodes with d matching taint.
echo                           items:
echo                             description: ^|-
echo                               The pod this Toleration is attached to tolerates any taint that matches
echo                               the triple ^<key,value,effect^> using the matching operator ^<operator^>.
echo                             properties:
echo                               effect:
echo                                 description: ^|-
echo                                   Effect indicates the taint effect to match. Empty means match all taint effects.
echo                                   When specified, allowed values are NoSchedule, PreferNoSchedule and NoExecute.
echo                                 type: string
echo                               key:
echo                                 description: ^|-
echo                                   Key is the taint key that the toleration applies to. Empty means match all taint keys.
echo                                   If the key is empty, operator must be Exists; this combination means to match all values and all keys.
echo                                 type: string
echo                               operator:
echo                                 description: ^|-
echo                                   Operator represents a key's relationship to the value.
echo                                   Valid operators are Exists and Equal. Defaults to Equal.
echo                                   Exists is equivalent to wildcard for value, so that a pod can
echo                                   tolerate all taints of a particular category.
echo                                 type: string
echo                               tolerationSeconds:
echo                                 description: ^|-
echo                                   TolerationSeconds represents the period of time the toleration (which must be
echo                                   of effect NoExecute, otherwise this field is ignored^) tolerates the taint. By default,
echo                                   it is not set, which means tolerate the taint forever (do not evict^). Zero and
echo                                   negative values will be treated as 0 (evict immediately^) by the system.
echo                                 format: int64
echo                                 type: integer
echo                               value:
echo                                 description: ^|-
echo                                   Value is the taint value the toleration matches to.
echo                                   If the operator is Exists, the value should be empty, otherwise just a regular string.
echo                                 type: string
echo                             type: object
echo                           type: array
echo                       type: object
echo                   required:
echo                   - name
echo                   - spec
echo                   type: object
echo                 type: array
echo               podAnnotations:
echo                 additionalProperties:
echo                   type: string
echo                 default: {}
echo                 description: PodAnnotations allows adding provider-specific pod annotations
echo                   to PubSubPlusEventBroker pods
echo                 type: object
echo               podDisruptionBudgetForHA:
echo                 default: false
echo                 description: ^|-
echo                   PodDisruptionBudgetForHA enables setting up PodDisruptionBudget for the broker pods in HA deployment.
echo                   This parameter is ignored for non-HA deployments (if redundancy is false^).
echo                 type: boolean
echo               podLabels:
echo                 additionalProperties:
echo                   type: string
echo                 default: {}
echo                 description: PodLabels allows adding provider-specific pod labels
echo                   to PubSubPlusEventBroker pods
echo                 type: object
echo               preSharedAuthKeySecret:
echo                 description: ^|-
echo                   PreSharedAuthKeySecret defines the PreSharedAuthKey Secret for PubSubPlusEventBroker. Random one will be generated if not provided.
echo                   When provided, ensure the secret key name is `preshared_auth_key`. For valid values refer to the Solace documentation https://docs.solace.com/Features/HA-Redundancy/Pre-Shared-Keys-SMB.htm?Highlight=pre%20shared.
echo                 nullable: true
echo                 type: string
echo               redundancy:
echo                 default: false
echo                 description: Redundancy true specifies HA deployment, false specifies
echo                   Non-HA.
echo                 type: boolean
echo               securityContext:
echo                 description: SecurityContext defines the pod security context for
echo                   the event broker.
echo                 properties:
echo                   fsGroup:
echo                     description: Specifies fsGroup in pod security context. 0 or unset
echo                       defaults either to 1000002, or if OpenShift detected to unspecified
echo                       (see documentation^)
echo                     format: int64
echo                     type: number
echo                   runAsUser:
echo                     description: Specifies runAsUser in pod security context. 0 or
echo                       unset defaults either to 1000001, or if OpenShift detected to
echo                       unspecified (see documentation^)
echo                     format: int64
echo                     type: number
echo                 type: object
echo               service:
echo                 description: Service defines broker service details.
echo                 properties:
echo                   annotations:
echo                     additionalProperties:
echo                       type: string
echo                     default: {}
echo                     description: Annotations allows adding provider-specific service
echo                       annotations
echo                     type: object
echo                   ports:
echo                     default:
echo                     - containerPort: 2222
echo                       name: tcp-ssh
echo                       protocol: TCP
echo                       servicePort: 2222
echo                     - containerPort: 8080
echo                       name: tcp-semp
echo                       protocol: TCP
echo                       servicePort: 8080
echo                     - containerPort: 1943
echo                       name: tls-semp
echo                       protocol: TCP
echo                       servicePort: 1943
echo                     - containerPort: 55555
echo                       name: tcp-smf
echo                       protocol: TCP
echo                       servicePort: 55555
echo                     - containerPort: 55003
echo                       name: tcp-smfcomp
echo                       protocol: TCP
echo                       servicePort: 55003
echo                     - containerPort: 55443
echo                       name: tls-smf
echo                       protocol: TCP
echo                       servicePort: 55443
echo                     - containerPort: 55556
echo                       name: tcp-smfroute
echo                       protocol: TCP
echo                       servicePort: 55556
echo                     - containerPort: 8008
echo                       name: tcp-web
echo                       protocol: TCP
echo                       servicePort: 8008
echo                     - containerPort: 1443
echo                       name: tls-web
echo                       protocol: TCP
echo                       servicePort: 1443
echo                     - containerPort: 9000
echo                       name: tcp-rest
echo                       protocol: TCP
echo                       servicePort: 9000
echo                     - containerPort: 9443
echo                       name: tls-rest
echo                       protocol: TCP
echo                       servicePort: 9443
echo                     - containerPort: 5672
echo                       name: tcp-amqp
echo                       protocol: TCP
echo                       servicePort: 5672
echo                     - containerPort: 5671
echo                       name: tls-amqp
echo                       protocol: TCP
echo                       servicePort: 5671
echo                     - containerPort: 1883
echo                       name: tcp-mqtt
echo                       protocol: TCP
echo                       servicePort: 1883
echo                     - containerPort: 8883
echo                       name: tls-mqtt
echo                       protocol: TCP
echo                       servicePort: 8883
echo                     - containerPort: 8000
echo                       name: tcp-mqttweb
echo                       protocol: TCP
echo                       servicePort: 8000
echo                     - containerPort: 8443
echo                       name: tls-mqttweb
echo                       protocol: TCP
echo                       servicePort: 8443
echo                     description: Ports specifies the ports to expose PubSubPlusEventBroker
echo                       services.
echo                     items:
echo                       description: Port defines parameters configure Service details
echo                         for the Broker
echo                       properties:
echo                         containerPort:
echo                           description: Port number to expose on the pod.
echo                           format: int32
echo                           type: number
echo                         name:
echo                           description: Unique name for the port that can be referred
echo                             to by services.
echo                           type: string
echo                         protocol:
echo                           default: TCP
echo                           description: Protocol for port. Must be UDP, TCP, or SCTP.
echo                           enum:
echo                           - TCP
echo                           - UDP
echo                           - SCTP
echo                           type: string
echo                         servicePort:
echo                           description: Port number to expose on the service
echo                           format: int32
echo                           type: number
echo                       required:
echo                       - containerPort
echo                       - name
echo                       - protocol
echo                       - servicePort
echo                       type: object
echo                     type: array
echo                   type:
echo                     default: LoadBalancer
echo                     description: ServiceType specifies how to expose the broker services.
echo                       Options include ClusterIP, NodePort, LoadBalancer (default^).
echo                     type: string
echo                 type: object
echo               serviceAccount:
echo                 description: ServiceAccount defines a ServiceAccount dedicated to
echo                   the PubSubPlusEventBroker
echo                 properties:
echo                   name:
echo                     description: ^|-
echo                       Name specifies the name of an existing ServiceAccount dedicated to the PubSubPlusEventBroker.
echo                       If this value is missing a new ServiceAccount will be created.
echo                     type: string
echo                 required:
echo                 - name
echo                 type: object
echo               storage:
echo                 description: Storage defines storage details for the broker.
echo                 properties:
echo                   customVolumeMount:
echo                     description: CustomVolumeMount can be used to show the data volume
echo                       should be mounted instead of using a storage class.
echo                     items:
echo                       description: StorageCustomVolumeMount defines Image details
echo                         and pulling configurations
echo                       properties:
echo                         name:
echo                           description: Defines the name of PubSubPlusEventBroker node
echo                             type that has the customVolumeMount spec defined
echo                           enum:
echo                           - Primary
echo                           - Backup
echo                           - Monitor
echo                           type: string
echo                         persistentVolumeClaim:
echo                           description: Defines the customVolumeMount that can be used
echo                             mount the data volume instead of using a storage class
echo                           properties:
echo                             claimName:
echo                               description: Defines the claimName of a custom PersistentVolumeClaim
echo                                 to be used instead
echo                               type: string
echo                           required:
echo                           - claimName
echo                           type: object
echo                       type: object
echo                     type: array
echo                   messagingNodeStorageSize:
echo                     default: 30Gi
echo                     description: MessagingNodeStorageSize if provided will assign
echo                       the minimum persistent storage to be used by the message nodes.
echo                     type: string
echo                   monitorNodeStorageSize:
echo                     default: 3Gi
echo                     description: MonitorNodeStorageSize if provided this will create
echo                       and assign the minimum recommended storage to Monitor pods.
echo                     type: string
echo                   slow:
echo                     default: false
echo                     description: Slow indicate slow storage is in use, an example
echo                       is NFS.
echo                     type: boolean
echo                   useStorageClass:
echo                     description: UseStrorageClass Name of the StorageClass to be used
echo                       to request persistent storage volumes. If undefined, the "default"
echo                       StorageClass will be used.
echo                     type: string
echo                 type: object
echo               systemScaling:
echo                 description: ^|-
echo                   SystemScaling provides exact fine-grained specification of the event broker scaling parameters
echo                   and the assigned CPU / memory resources to the Pod.
echo                 type: object
echo                 x-kubernetes-preserve-unknown-fields: true
echo               timezone:
echo                 default: UTC
echo                 description: Defines the timezone for the event broker container,
echo                   if undefined default is UTC. Valid values are tz database time zone
echo                   names.
echo                 type: string
echo               tls:
echo                 description: TLS provides TLS configuration for the event broker.
echo                 properties:
echo                   certFilename:
echo                     default: tls.key
echo                     description: Name of the Certificate file in the `serverCertificatesSecret`
echo                     type: string
echo                   certKeyFilename:
echo                     default: tls.crt
echo                     description: Name of the Key file in the `serverCertificatesSecret`
echo                     type: string
echo                   enabled:
echo                     default: false
echo                     description: Enabled true enables TLS for the broker.
echo                     type: boolean
echo                   serverTlsConfigSecret:
echo                     default: example-tls-secret
echo                     description: Specifies the tls configuration secret to be used
echo                       for the broker
echo                     type: string
echo                 type: object
echo               updateStrategy:
echo                 default: automatedRolling
echo                 description: UpdateStrategy specifies how to update an existing deployment.
echo                   manualPodRestart waits for user intervention.
echo                 enum:
echo                 - automatedRolling
echo                 - manualPodRestart
echo                 type: string
echo             type: object
echo           status:
echo             description: EventBrokerStatus defines the observed state of the PubSubPlusEventBroker
echo             properties:
echo               broker:
echo                 description: Broker section provides the broker status
echo                 properties:
echo                   adminCredentialsSecret:
echo                     type: string
echo                   brokerImage:
echo                     type: string
echo                   haDeployment:
echo                     type: string
echo                   serviceName:
echo                     type: string
echo                   serviceType:
echo                     type: string
echo                   statefulSets:
echo                     items:
echo                       type: string
echo                     type: array
echo                   tlsSecret:
echo                     type: string
echo                   tlsSupport:
echo                     type: string
echo                 type: object
echo               conditions:
echo                 description: Conditions provide information about the observed status
echo                   of the deployment
echo                 items:
echo                   description: "Condition contains details for one aspect of the current
echo                     state of this API Resource.\n---\nThis struct is intended for
echo                     direct use as an array at the field path .status.conditions.  For
echo                     example,\n\n\n\ttype FooStatus struct{\n\t    // Represents the
echo                     observations of a foo's current state.\n\t    // Known .status.conditions.type
echo                     are: \"Available\", \"Progressing\", and \"Degraded\"\n\t    //
echo                     +patchMergeKey=type\n\t    // +patchStrategy=merge\n\t    // +listType=map\n\t
echo                     \   // +listMapKey=type\n\t    Conditions []metav1.Condition `json:\"conditions,omitempty\"
echo                     patchStrategy:\"merge\" patchMergeKey:\"type\" protobuf:\"bytes,1,rep,name=conditions\"`\n\n\n\t
echo                     \   // other fields\n\t}"
echo                   properties:
echo                     lastTransitionTime:
echo                       description: ^|-
echo                         lastTransitionTime is the last time the condition transitioned from one status to another.
echo                         This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.
echo                       format: date-time
echo                       type: string
echo                     message:
echo                       description: ^|-
echo                         message is a human readable message indicating details about the transition.
echo                         This may be an empty string.
echo                       maxLength: 32768
echo                       type: string
echo                     observedGeneration:
echo                       description: ^|-
echo                         observedGeneration represents the .metadata.generation that the condition was set based upon.
echo                         For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date
echo                         with respect to the current state of the instance.
echo                       format: int64
echo                       minimum: 0
echo                       type: integer
echo                     reason:
echo                       description: ^|-
echo                         reason contains a programmatic identifier indicating the reason for the condition's last transition.
echo                         Producers of specific condition types may define expected values and meanings for this field,
echo                         and whether the values are considered a guaranteed API.
echo                         The value should be a CamelCase string.
echo                         This field may not be empty.
echo                       maxLength: 1024
echo                       minLength: 1
echo                       pattern: ^^[A-Za-z]([A-Za-z0-9_,:]*[A-Za-z0-9_]^)?$
echo                       type: string
echo                     status:
echo                       description: status of the condition, one of True, False, Unknown.
echo                       enum:
echo                       - "True"
echo                       - "False"
echo                       - Unknown
echo                       type: string
echo                     type:
echo                       description: ^|-
echo                         type of condition in CamelCase or in foo.example.com/CamelCase.
echo                         ---
echo                         Many .condition.type values are consistent across resources like Available, but because arbitrary conditions can be
echo                         useful (see .node.status.conditions^), the ability to deconflict is important.
echo                         The regex it matches is (dns1123SubdomainFmt/^)?(qualifiedNameFmt^)
echo                       maxLength: 316
echo                       pattern: ^^([a-z0-9]([-a-z0-9]*[a-z0-9]^)?(\.[a-z0-9]([-a-z0-9]*[a-z0-9]^)?^)*/^)?(([A-Za-z0-9][-A-Za-z0-9_.]*^)?[A-Za-z0-9]^)$
echo                       type: string
echo                   required:
echo                   - lastTransitionTime
echo                   - message
echo                   - reason
echo                   - status
echo                   - type
echo                   type: object
echo                 type: array
echo               podsList:
echo                 description: PodsList are the names of the eventbroker and optionally
echo                   the monitoring pods
echo                 items:
echo                   type: string
echo                 type: array
echo               prometheusMonitoring:
echo                 description: Monitoring sectionprovides monitoring support status
echo                 properties:
echo                   enabled:
echo                     type: string
echo                   exporterImage:
echo                     type: string
echo                   serviceName:
echo                     type: string
echo                 type: object
echo             type: object
echo         type: object
echo     served: true
echo     storage: true
echo     subresources:
echo       status: {}
echo ---
echo apiVersion: v1
echo kind: ServiceAccount
echo metadata:
echo   name: pubsubplus-eventbroker-operator
echo   namespace: pubsubplus-operator-system
echo ---
echo apiVersion: rbac.authorization.k8s.io/v1
echo kind: Role
echo metadata:
echo   name: pubsubplus-eventbroker-operator-leader-election-role
echo   namespace: pubsubplus-operator-system
echo rules:
echo - apiGroups:
echo   - ""
echo   resources:
echo   - configmaps
echo   verbs:
echo   - get
echo   - list
echo   - watch
echo   - create
echo   - update
echo   - patch
echo   - delete
echo - apiGroups:
echo   - coordination.k8s.io
echo   resources:
echo   - leases
echo   verbs:
echo   - get
echo   - list
echo   - watch
echo   - create
echo   - update
echo   - patch
echo   - delete
echo - apiGroups:
echo   - ""
echo   resources:
echo   - events
echo   verbs:
echo   - create
echo   - patch
echo ---
echo apiVersion: rbac.authorization.k8s.io/v1
echo kind: ClusterRole
echo metadata:
echo   name: pubsubplus-eventbroker-operator-role
echo rules:
echo - apiGroups:
echo   - ""
echo   resources:
echo   - configmaps
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - ""
echo   resources:
echo   - events
echo   verbs:
echo   - create
echo   - patch
echo - apiGroups:
echo   - ""
echo   resources:
echo   - namespaces
echo   verbs:
echo   - get
echo   - list
echo   - watch
echo - apiGroups:
echo   - ""
echo   resources:
echo   - pods
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - ""
echo   resources:
echo   - secrets
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - ""
echo   resources:
echo   - serviceaccounts
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - ""
echo   resources:
echo   - services
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - apps
echo   resources:
echo   - deployments
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - apps
echo   resources:
echo   - statefulsets
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - policy
echo   resources:
echo   - poddisruptionbudgets
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - pubsubplus.solace.com
echo   resources:
echo   - pubsubpluseventbrokers
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - pubsubplus.solace.com
echo   resources:
echo   - pubsubpluseventbrokers/finalizers
echo   verbs:
echo   - update
echo - apiGroups:
echo   - pubsubplus.solace.com
echo   resources:
echo   - pubsubpluseventbrokers/status
echo   verbs:
echo   - get
echo   - patch
echo   - update
echo - apiGroups:
echo   - rbac.authorization.k8s.io
echo   resources:
echo   - rolebindings
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo - apiGroups:
echo   - rbac.authorization.k8s.io
echo   resources:
echo   - roles
echo   verbs:
echo   - create
echo   - delete
echo   - get
echo   - list
echo   - patch
echo   - update
echo   - watch
echo ---
echo apiVersion: rbac.authorization.k8s.io/v1
echo kind: RoleBinding
echo metadata:
echo   name: pubsubplus-eventbroker-operator-leader-election-rolebinding
echo   namespace: pubsubplus-operator-system
echo roleRef:
echo   apiGroup: rbac.authorization.k8s.io
echo   kind: Role
echo   name: pubsubplus-eventbroker-operator-leader-election-role
echo subjects:
echo - kind: ServiceAccount
echo   name: pubsubplus-eventbroker-operator
echo   namespace: pubsubplus-operator-system
echo ---
echo apiVersion: rbac.authorization.k8s.io/v1
echo kind: ClusterRoleBinding
echo metadata:
echo   name: pubsubplus-eventbroker-operator-rolebinding
echo roleRef:
echo   apiGroup: rbac.authorization.k8s.io
echo   kind: ClusterRole
echo   name: pubsubplus-eventbroker-operator-role
echo subjects:
echo - kind: ServiceAccount
echo   name: pubsubplus-eventbroker-operator
echo   namespace: pubsubplus-operator-system
echo ---
echo apiVersion: apps/v1
echo kind: Deployment
echo metadata:
echo   labels:
echo     app.kubernetes.io/component: controller
echo     app.kubernetes.io/name: solace-pubsubplus-eventbroker-operator
echo     app.kubernetes.io/version: version
echo     control-plane: controller-manager
echo   name: pubsubplus-eventbroker-operator
echo   namespace: pubsubplus-operator-system
echo spec:
echo   replicas: 1
echo   selector:
echo     matchLabels:
echo       control-plane: controller-manager
echo   template:
echo     metadata:
echo       annotations:
echo         kubectl.kubernetes.io/default-container: manager
echo       labels:
echo         app.kubernetes.io/component: controller
echo         app.kubernetes.io/name: solace-pubsubplus-eventbroker-operator
echo         app.kubernetes.io/version: version
echo         control-plane: controller-manager
echo     spec:
echo       containers:
echo       - args:
echo         - --leader-elect
echo         - --zap-log-level=info
echo         command:
echo         - /manager
echo         env:
echo         - name: WATCH_NAMESPACE
echo           value: %watch_namespace%
echo         image: %operator_image%
echo         imagePullPolicy: Always
echo         livenessProbe:
echo           httpGet:
echo             path: /healthz
echo             port: 8081
echo           initialDelaySeconds: 15
echo           periodSeconds: 20
echo         name: manager
echo         readinessProbe:
echo           httpGet:
echo             path: /readyz
echo             port: 8081
echo           initialDelaySeconds: 5
echo           periodSeconds: 10
echo         resources:
echo           limits:
echo             cpu: %op_limits_cpu%
echo             memory: %op_limits_mem%
echo           requests:
echo             cpu: 10m
echo             memory: 64Mi
echo         securityContext:
echo           allowPrivilegeEscalation: false
echo           capabilities:
echo             drop:
echo             - ALL
echo       imagePullSecrets:
echo       - name: regcred
echo       securityContext:
echo         runAsNonRoot: true
echo         seccompProfile:
echo           type: RuntimeDefault
echo       serviceAccountName: pubsubplus-eventbroker-operator
echo       terminationGracePeriodSeconds: 10
) > %op_tmp_yaml%

%kube% apply -f %op_tmp_yaml%

rem del %op_tmp_yaml%