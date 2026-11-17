package com.zentrapay.backend.service.common;

import com.fasterxml.jackson.annotation.ObjectIdGenerator;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import org.hibernate.id.uuid.UuidGenerator;

public class Utils {

    public static String getZentag(String currencyCode, String phoneNumber) {
        return phoneNumber + "_" + currencyCode + "@zentrapay";
    }

    public static String getTxnRef() {
        return NanoIdGenerator.generate("ZENREF_", 10);
    }
}