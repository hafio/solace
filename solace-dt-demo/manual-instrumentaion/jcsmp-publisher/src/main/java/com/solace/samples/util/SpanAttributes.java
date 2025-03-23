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

public interface SpanAttributes {

    /**
     * Represent messaging operations like Create Message, Send Message, Receive a Message and Process
     * a Message.
     */
    enum MessagingOperation {
        CREATE, SEND, RECEIVE, PROCESS
    }

    /**
     * Example attributes that can be included as Span Attributes.
     */
    enum MessagingAttribute {
        SERVICE_NAME("service.name"),
        OPERATION("messaging.operation"),
        SYSTEM("messaging.system"),
        DESTINATION("messaging.destination"),
        DESTINATION_KIND("messaging.destination_kind"),
        IS_TEMP_DESTINATION("messaging.temp_destination"),
        PROTOCOL("messaging.protocol"),
        PROTOCOL_VERSION("messaging.protocol.version"),
        SERVICE_URI("messaging.uri"),
        MESSAGE_ID("messaging.message_id");

        private final String attributeName;

        MessagingAttribute(String attributeName) {
            this.attributeName = attributeName;
        }

        @Override
        public String toString() {
            return attributeName;
        }
    }

    /**
     * Values for {@link MessagingAttribute#DESTINATION_KIND} either a Queue or Topic
     */
    enum MessageDestinationKind {
        TOPIC, QUEUE
    }
}