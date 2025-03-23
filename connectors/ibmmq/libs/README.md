# Solace PubSub+ Connector for IBM MQ: Java dependencies in the `/libs` folder
Solace
Corporation https://solace.com

*Revision: 2.9.0*
<br/>*Revision Date: 2025-03-06*

## Table of Contents

-   [Preface]
-   [IBM MQ Classes for Jakarta Messaging]
-   [Micrometer Metrics exporter dependencies]

## Preface

This `/libs` directory is provided as a default location for the Java library dependencies (external `jar` files) that are either required or required only when using certain features of the connector (such as Prometheus libraries when using the metrics export to Prometheus feature in your connector configuration).

Solace does not provide the required JAR files due to licensing considerations. These JAR files are required as part of the deployment of the connector for it to operate correctly.

## IBM MQ Classes for Jakarta Messaging

The Connector uses IBM MQ Classes for Jakarta Messaging to provide connection and message processing on MQ Queue Managers. The MQ Classes for Jakarta Messaging can be obtained in a number of ways, 2 ways are listed below:

1.  Via IBM Fix Central - See [IBM MQ documentation]

2.  Via Maven Central Repository - the required `com.ibm.mq.jakarta.client` library and all its dependencies can be downloaded from [Maven Central Repository].

    > **IMPORTANT**
    > 
    > If you are manually downloading `com.ibm.mq.jakarta.client` from Maven, you must also download compatible versions of the *Compile Dependencies* listed in the `Dependencies` tab.

As an example, v2.0.0 of the Connector has been mostly developed and tested using [version 9.3.4.0]. The compile dependencies listed for this version of the `com.ibm.mq.jakarta.client` are:

-   `jackson-annotations` v2.15.2

-   `jackson-core` v2.15.2

-   `jackson-databind` v2.15.2

-   `jakarta.jms-api` v3.1.0

-   `bcpkix-jdk15to18` v1.76

-   `bcprov-jdk15to18` v1.76

-   `bcutil-jdk15to18` v1.76

-   `json` 20230618

> **NOTE**
> 
> Different versions of the IBM MQ Classes for Jakarta Messaging may have different dependencies and/or dependency versions. Use one of the two methods above to make sure you obtain the proper client and dependencies for your MQ Queue Manager. The above list is just an example of a configuration used by Solace to develop and test the Connector.

## Micrometer Metrics exporter dependencies

The connector makes use of [Micrometer.io] to provide easy, configuration-driven exporting of connector metrics to many 3rd-party metrics monitoring solutions (see the full list on the Micrometer site).

These services can be configured in the connector configuration (there are commented in the sample configuration provided to guide you), but must have the necessary Java dependencies in the `/libs` directory to operate.

The JAR files that are necessary depend on which metrics service you are configuring. The details for each provider can be found in the [Micrometer documentation]. For example, for [Prometheus], the Micrometer instructions list `io.micrometer.micrometer-registry-prometheus` as the main client library required and the Maven Central page for this library provides the download links for the main `jar` and its compile dependencies. These JAR files are placed in the connector’s `/libs` directory.

  [Preface]: #preface
  [IBM MQ Classes for Jakarta Messaging]: #ibm-mq-classes-for-jakarta-messaging
  [Micrometer Metrics exporter dependencies]: #micrometer-metrics-exporter-dependencies
  [IBM MQ documentation]: https://www.ibm.com/docs/en/ibm-mq/9.3?topic=umcjm-obtaining-mq-classes-jms-mq-classes-jakarta-messaging-separately
  [Maven Central Repository]: https://central.sonatype.com/artifact/com.ibm.mq/com.ibm.mq.jakarta.client
  [version 9.3.4.0]: https://central.sonatype.com/artifact/com.ibm.mq/com.ibm.mq.jakarta.client/9.3.4.0
  [Micrometer.io]: https://micrometer.io/
  [Micrometer documentation]: https://docs.micrometer.io/micrometer/reference/implementations.html
  [Prometheus]: https://prometheus.io/
