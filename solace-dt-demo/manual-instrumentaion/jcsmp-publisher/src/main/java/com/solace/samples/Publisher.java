/*
 * Copyright 2021-2022 Solace Corporation. All rights reserved.
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

package com.solace.samples;

import java.io.IOException;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;

import com.solace.messaging.trace.propagation.SolaceJCSMPTextMapGetter;
import com.solace.messaging.trace.propagation.SolaceJCSMPTextMapSetter;
import com.solace.samples.util.JcsmpTracingUtil;
import com.solace.samples.util.SpanAttributes;
import com.solacesystems.jcsmp.*;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.TextMapPropagator;
import io.opentelemetry.context.Context;

public class Publisher {

    private static final String SAMPLE_NAME = Publisher.class.getSimpleName();
    private static final String SERVICE_NAME = "SolaceJCSMPPublisherManualInstrumentation";
    public static final String TOPIC_PREFIX = "solace/tracing";  // used as the topic "root"
    private static final String API = "JCSMP";
    private static final int APPROX_MSG_RATE_PER_SEC = 5;
    private static final int PAYLOAD_SIZE = 100;

    private static volatile int msgSentCounter = 0;                   // num messages sent
    private static volatile boolean isShutdown = false;

    /** Main method. */
    public static void main(String... args) throws JCSMPException, IOException, InterruptedException {
        if (args.length < 3) {  // Check command line arguments
            System.out.printf("Usage: %s <host:port> <message-vpn> <client-username> [password]%n%n", SAMPLE_NAME);
            System.exit(-1);
        }
        System.out.println(API + " " + SAMPLE_NAME + " initializing...");

        final JCSMPProperties properties = new JCSMPProperties();
        properties.setProperty(JCSMPProperties.HOST, args[0]);          // host:port
        properties.setProperty(JCSMPProperties.VPN_NAME,  args[1]);     // message-vpn
        properties.setProperty(JCSMPProperties.USERNAME, args[2]);      // client-username
        if (args.length > 3) {
            properties.setProperty(JCSMPProperties.PASSWORD, args[3]);  // client-password
        }
        properties.setProperty(JCSMPProperties.GENERATE_SEQUENCE_NUMBERS, true);  // not required, but interesting
        JCSMPChannelProperties channelProps = new JCSMPChannelProperties();
        channelProps.setReconnectRetries(20);      // recommended settings
        channelProps.setConnectRetriesPerHost(5);  // recommended settings
        // https://docs.solace.com/Solace-PubSub-Messaging-APIs/API-Developer-Guide/Configuring-Connection-T.htm
        properties.setProperty(JCSMPProperties.CLIENT_CHANNEL_PROPERTIES, channelProps);
        final JCSMPSession session;
        session = JCSMPFactory.onlyInstance().createSession(properties, null, new SessionEventHandler() {
            @Override
            public void handleEvent(SessionEventArgs event) {  // could be reconnecting, connection lost, etc.
                System.out.printf("### Received a Session event: %s%n", event);
            }
        });
        session.connect();  // connect to the broker

        // Simple anonymous inner-class for handling publishing events
        final XMLMessageProducer producer;
        producer = session.getMessageProducer(new JCSMPStreamingPublishCorrelatingEventHandler() {
            // unused in Direct Messaging application, only for Guaranteed/Persistent publishing application
            @Override public void responseReceivedEx(Object key) {
            }

            // can be called for ACL violations, connection loss, and Persistent NACKs
            @Override
            public void handleErrorEx(Object key, JCSMPException cause, long timestamp) {
                System.out.printf("### Producer handleErrorEx() callback: %s%n", cause);
                if (cause instanceof JCSMPTransportException) {  // all reconnect attempts failed
                    isShutdown = true;  // let's quit; or, could initiate a new connection attempt
                } else if (cause instanceof JCSMPErrorResponseException) {  // might have some extra info
                    JCSMPErrorResponseException e = (JCSMPErrorResponseException)cause;
                    System.out.println(JCSMPErrorResponseSubcodeEx.getSubcodeAsString(e.getSubcodeEx())
                            + ": " + e.getResponsePhrase());
                    System.out.println(cause);
                }
            }
        });

        ScheduledExecutorService statsPrintingThread = Executors.newSingleThreadScheduledExecutor();
        statsPrintingThread.scheduleAtFixedRate(() -> {
            System.out.printf("%s %s Published msgs/s: %,d%n",API,SAMPLE_NAME,msgSentCounter);  // simple way of calculating message rates
            msgSentCounter = 0;
        }, 1, 1, TimeUnit.SECONDS);

        System.out.println(API + " " + SAMPLE_NAME + " connected, and running. Press [ENTER] to quit.");
        // preallocate a binary message, reuse it each loop, for performance
        final BytesMessage message = JCSMPFactory.onlyInstance().createMessage(BytesMessage.class);
        byte[] payload = new byte[PAYLOAD_SIZE];  // preallocate memory, for reuse, for performance
        // loop the main thread, waiting for a quit signal
        while (System.in.available() == 0 && !isShutdown) {
            try {
                message.setData(payload);
                message.setApplicationMessageId(UUID.randomUUID().toString());  // as an example of a header
                String topicString = new StringBuilder(TOPIC_PREFIX).toString();
                Topic topic = JCSMPFactory.onlyInstance().createTopic(topicString);

                //Extract tracing context from message, if any using the SolaceJCSMPTextMapGetter
                //It is always advised to extract context before injecting new one
                final SolaceJCSMPTextMapGetter getter = new SolaceJCSMPTextMapGetter();
                final Context extractedContext = JcsmpTracingUtil.openTelemetry.getPropagators().getTextMapPropagator()
                        .extract(Context.current(), message, getter);

                //Set the extract context as current context
                try (Scope parent = extractedContext.makeCurrent()) {
                    //Create a child span and set extracted/current context as parent of this span
                    final Span sendSpan = JcsmpTracingUtil.tracer
                            .spanBuilder(SERVICE_NAME + " " + SpanAttributes.MessagingOperation.SEND)
                            .setSpanKind(SpanKind.CLIENT)
                            .setAttribute(SpanAttributes.MessagingAttribute.DESTINATION_KIND.toString(),
                                    SpanAttributes.MessageDestinationKind.TOPIC.toString())
                            .setAttribute(SpanAttributes.MessagingAttribute.IS_TEMP_DESTINATION.toString(), "true")
                            //Set more attributes as needed
                            .setAttribute("myKey", "myValue" + ThreadLocalRandom.current().nextInt(1, 3))
                            .setParent(extractedContext) // set extractedContext as parent
                            .startSpan();

                    try (Scope scope = sendSpan.makeCurrent()) {
                        final SolaceJCSMPTextMapSetter setter = new SolaceJCSMPTextMapSetter();
                        final TextMapPropagator propagator = JcsmpTracingUtil.openTelemetry.getPropagators().getTextMapPropagator();
                        //and then inject new current context (set by sendSpan.makeCurrent()) in the message
                        propagator.inject(Context.current(), message, setter);
                        try {
                            producer.send(message, topic);  // send the message
                            msgSentCounter++;  // add one
                            message.reset();   // reuse this message, to avoid having to recreate it: better performance
                        } catch (JCSMPException e) {
                            System.out.printf("### Caught while trying to producer.send(): %s%n", e);
                            if (e instanceof JCSMPTransportException) {  // all reconnect attempts failed
                                isShutdown = true;  // let's quit; or, could initiate a new connection attempt
                            }
                            throw e;
                        }
                    } catch (Exception e) {
                        sendSpan.recordException(e); //Span can record exception if any
                        sendSpan.setStatus(StatusCode.ERROR, e.getMessage()); //Set span status as ERROR/FAILED
                    } finally {
                        sendSpan.end(); //End sendSpan. Span data is exported when span.end() is called.
                    }
                }
            } finally {  // add a delay between messages
                try {
                    Thread.sleep(1000 / APPROX_MSG_RATE_PER_SEC);  // do Thread.sleep(0) for max speed
                    // Note: STANDARD Edition Solace PubSub+ broker is limited to 10k msg/s max ingress
                } catch (InterruptedException e) {
                    isShutdown = true;
                }
            }
        }
        isShutdown = true;
        statsPrintingThread.shutdown();  // stop printing stats
        session.closeSession();  // will also close producer object
        System.out.println("Main thread quitting.");
    }
}