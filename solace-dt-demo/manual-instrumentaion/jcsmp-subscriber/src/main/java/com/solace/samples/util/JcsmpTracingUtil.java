/*
 * Copyright 2022-2023 Solace Corporation. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package com.solace.samples.util;

import static com.solace.samples.util.SpanAttributes.MessagingAttribute.*;
import static io.opentelemetry.api.trace.SpanKind.CONSUMER;
import static io.opentelemetry.api.trace.SpanKind.PRODUCER;
import com.solace.messaging.trace.propagation.SolaceJCSMPTextMapGetter;
import com.solace.messaging.trace.propagation.SolaceJCSMPTextMapSetter;
import com.solacesystems.jcsmp.BytesXMLMessage;
import com.solacesystems.jcsmp.Destination;
import com.solacesystems.jcsmp.Queue;
import com.solacesystems.jcsmp.Topic;
import com.solacesystems.jcsmp.XMLMessage;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.baggage.propagation.W3CBaggagePropagator;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;
import io.opentelemetry.context.propagation.ContextPropagators;
import io.opentelemetry.context.propagation.TextMapPropagator;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.semconv.resource.attributes.ResourceAttributes;
import java.util.concurrent.TimeUnit;


public class JcsmpTracingUtil {

    private JcsmpTracingUtil() {

    }

    public static final String SERVICE_NAME = "SolaceJCSMPManualOpenTelemetry";
    public static final OpenTelemetry openTelemetry;
    public static final Tracer tracer;

    private static final SolaceJCSMPTextMapSetter setter = new SolaceJCSMPTextMapSetter();
    private static final SolaceJCSMPTextMapGetter getter = new SolaceJCSMPTextMapGetter();

    //Init Tracing in static initializer
    static {
        //OpenTelemetry Resource object
        Resource resource = Resource.getDefault().merge(Resource.create(
                Attributes.of(ResourceAttributes.SERVICE_NAME, SERVICE_NAME)));

        //OpenTelemetry provides gRPC, HTTP and NoOp span exporter.
        //Change the collector host/ip and port below if it's not running on default localhost:4317
        OtlpGrpcSpanExporter spanExporter = OtlpGrpcSpanExporter.builder()
                //.setEndpoint("http://localhost:4317")
                .build();

        //Use OpenTelemetry SdkTracerProvider as TracerProvider
        SdkTracerProvider sdkTracerProvider = SdkTracerProvider.builder()
                .addSpanProcessor(BatchSpanProcessor.builder(spanExporter)
                        .setScheduleDelay(100, TimeUnit.MILLISECONDS).build())
                .setResource(resource)
                .build();

        //This Instance can be used to get tracer if it is not configured as global
        openTelemetry = OpenTelemetrySdk.builder()
                .setTracerProvider(sdkTracerProvider)
                .setPropagators(
                        ContextPropagators.create(
                                TextMapPropagator.composite(
                                        W3CTraceContextPropagator.getInstance(), //W3C Context Propagator
                                        W3CBaggagePropagator.getInstance()  //W3C Baggage Propagator
                                )
                        )
                ).buildAndRegisterGlobal();

        tracer = GlobalOpenTelemetry.getTracer(SERVICE_NAME);
    }
}